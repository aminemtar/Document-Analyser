import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';
import 'usage_service.dart';

/// Whether an interstitial should be shown now. Pure, so it can be tested.
///
/// Gentle on purpose, because annoyed users leave and bad reviews cost more
/// than the ads earn:
/// - never before the user has completed [minTotalAnalyses] analyses, and not
///   during their first [grace] after installing,
/// - only after [every] completed analyses, at least [minGap] apart,
/// - at most [maxPerDay] a day.
bool shouldShowInterstitial({
  required int analysesSinceLastAd,
  required DateTime? lastShown,
  required DateTime now,
  int every = 2,
  Duration minGap = const Duration(minutes: 4),
  int totalAnalyses = 1 << 20,
  int minTotalAnalyses = 3,
  DateTime? firstRun,
  Duration grace = const Duration(hours: 24),
  int shownToday = 0,
  int maxPerDay = 3,
}) {
  if (totalAnalyses < minTotalAnalyses) return false;
  if (firstRun != null && now.difference(firstRun) < grace) return false;
  if (shownToday >= maxPerDay) return false;
  if (analysesSinceLastAd < every) return false;
  if (lastShown != null && now.difference(lastShown) < minGap) return false;
  return true;
}

/// AdMob: consent form, banner, interstitial and rewarded ads.
///
/// Everything here is a no-op on unsupported platforms, in tests, while the
/// user is ad-free, and when ads fail to load, so the app never depends on an ad.
abstract final class AdService {
  /// True once the Mobile Ads SDK is initialized and ads may be requested.
  static final ValueNotifier<bool> ready = ValueNotifier(false);

  /// True while a rewarded ad is loaded and can be shown.
  static final ValueNotifier<bool> rewardedReady = ValueNotifier(false);

  static int _interstitialFailures = 0;
  static int _rewardedFailures = 0;

  /// Tries again after a failed load, waiting longer each time (30 s, 60 s,
  /// 2 min, ...) up to 5 attempts, so a bad connection does not hammer AdMob.
  static void _retry(int attempt, void Function() load) {
    if (attempt > 5) return;
    Timer(Duration(seconds: 30 * (1 << (attempt - 1))), load);
  }

  static InterstitialAd? _interstitial;
  static RewardedAd? _rewarded;
  static int _analysesSinceAd = 0;
  static DateTime? _lastInterstitial;

  static bool get supported =>
      !kIsWeb &&
      (Platform.isAndroid || Platform.isIOS) &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  /// Ads are shown only to free users.
  static bool get adsAllowed => supported;

  static Future<void> init() async {
    if (!supported) return;
    await UsageService.isAdFree();
    await UsageService.firstRun();
    try {
      await _gatherConsent();
      if (!await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.initialize();
      ready.value = true;
      _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      debugPrint('Ads unavailable: $e');
    }
  }

  /// Shows the EU/UK consent form when it is required (Google's UMP).
  static Future<void> _gatherConsent() async {
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) => finish());
      },
      (_) => finish(),
    );
    await done.future.timeout(const Duration(seconds: 20), onTimeout: () {});
  }

  /// Lets the user change their consent choice later (shown in Profile when
  /// the consent form is required in their region).
  static Future<bool> privacyOptionsRequired() async {
    if (!supported) return false;
    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  static Future<void> showPrivacyOptions() async {
    if (!supported) return;
    final done = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((_) {
      if (!done.isCompleted) done.complete();
    });
    await done.future.timeout(const Duration(seconds: 30), onTimeout: () {});
  }

  static void _loadInterstitial() {
    if (!supported) return;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialFailures = 0;
        },
        onAdFailedToLoad: (_) {
          _interstitial = null;
          _retry(++_interstitialFailures, _loadInterstitial);
        },
      ),
    );
  }

  static void _loadRewarded() {
    if (!supported) return;
    RewardedAd.load(
      adUnitId: AdConfig.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewardedFailures = 0;
          rewardedReady.value = true;
        },
        onAdFailedToLoad: (_) {
          _rewarded = null;
          rewardedReady.value = false;
          _retry(++_rewardedFailures, _loadRewarded);
        },
      ),
    );
  }

  /// Call after each successful analysis. Shows a full-screen ad at a natural
  /// break (the result is ready, the user has not started anything else),
  /// following the gentle rules of [shouldShowInterstitial].
  static Future<void> onAnalysisCompleted() async {
    if (!adsAllowed || !ready.value) return;
    _analysesSinceAd++;
    final now = DateTime.now();
    if (!shouldShowInterstitial(
        analysesSinceLastAd: _analysesSinceAd,
        lastShown: _lastInterstitial,
        now: now,
        totalAnalyses: await UsageService.totalAnalyses(),
        firstRun: await UsageService.firstRun(now: now),
        shownToday: await UsageService.interstitialsToday(now: now))) {
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    _analysesSinceAd = 0;
    _lastInterstitial = now;
    await UsageService.recordInterstitial(now: now);
    ad.show();
  }

  /// Plays a rewarded ad. Returns true only if the user earned the reward
  /// (watched it to the end).
  static Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (!supported || ad == null) return false;
    _rewarded = null;
    rewardedReady.value = false;
    final result = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (!result.isCompleted) result.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadRewarded();
        if (!result.isCompleted) result.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return result.future;
  }
}
