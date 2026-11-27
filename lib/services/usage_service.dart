import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Free monthly limit, bonus analyses from rewarded ads and daily caps, stored
/// on the device only.
///
/// The limit is local: clearing the app data resets it. A hard limit needs
/// a server to enforce it.
abstract final class UsageService {
  static const freeMonthlyAnalyses = 3;
  /// Daily fair-use caps (per calendar day, on this device).
  static const freeDailyQuestions = 10;
  static const dailyLimitMessage =
      'Daily limit reached for this feature. Please come back tomorrow.';
  static const _bonusKey = 'bonus_analyses';

  /// Smart-ads rules (all local, see AdService).
  static const maxInterstitialsPerDay = 3;
  static const maxRewardedPerDay = 8;
  static const questionBonusSize = 5;
  static const adFreeDuration = Duration(hours: 24);
  static const _firstRunKey = 'first_run_ms';
  static const _totalKey = 'total_analyses';
  static const _adFreeKey = 'ad_free_until_ms';

  static String _monthKey(DateTime now) => 'usage_${now.year}_${now.month}';

  /// True while the user has earned an ad-free period by watching a rewarded ad.
  static final ValueNotifier<bool> adFreeNotifier = ValueNotifier(false);
  static Timer? _adFreeTimer;

  static Future<DateTime?> adFreeUntil() async {
    final ms = (await SharedPreferences.getInstance()).getInt(_adFreeKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Reads the saved ad-free period and keeps [adFreeNotifier] correct, also
  /// when it runs out while the app is open.
  static Future<bool> isAdFree({DateTime? now}) async {
    final until = await adFreeUntil();
    final t = now ?? DateTime.now();
    final active = until != null && until.isAfter(t);
    adFreeNotifier.value = active;
    _adFreeTimer?.cancel();
    if (active) {
      _adFreeTimer = Timer(until.difference(t) + const Duration(seconds: 1),
          () => isAdFree());
    }
    return active;
  }

  /// Starts (or extends) the ad-free period.
  static Future<void> grantAdFree(
      {Duration duration = adFreeDuration, DateTime? now}) async {
    final t = now ?? DateTime.now();
    final current = await adFreeUntil();
    final base = current != null && current.isAfter(t) ? current : t;
    await (await SharedPreferences.getInstance())
        .setInt(_adFreeKey, base.add(duration).millisecondsSinceEpoch);
    await isAdFree(now: now);
  }

  static String _adDayKey(String kind, DateTime now) =>
      'ads_${kind}_${now.year}_${now.month}_${now.day}';

  static Future<int> _count(String key) async =>
      (await SharedPreferences.getInstance()).getInt(key) ?? 0;

  static Future<void> _bump(String key, [int by = 1]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + by);
  }

  static Future<int> interstitialsToday({DateTime? now}) =>
      _count(_adDayKey('inter', now ?? DateTime.now()));
  static Future<void> recordInterstitial({DateTime? now}) =>
      _bump(_adDayKey('inter', now ?? DateTime.now()));

  static Future<int> rewardedToday({DateTime? now}) =>
      _count(_adDayKey('reward', now ?? DateTime.now()));
  static Future<void> recordRewarded({DateTime? now}) =>
      _bump(_adDayKey('reward', now ?? DateTime.now()));
  static Future<bool> canWatchRewarded({DateTime? now}) async =>
      await rewardedToday(now: now) < maxRewardedPerDay;

  /// Extra assistant questions earned today by watching a rewarded ad.
  static Future<void> addQuestionBonus(
          [int count = questionBonusSize, DateTime? now]) =>
      _bump(_adDayKey('askbonus', now ?? DateTime.now()), count);

  /// When the app was first opened (saved the first time it is asked).
  static Future<DateTime> firstRun({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_firstRunKey);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    final t = now ?? DateTime.now();
    await prefs.setInt(_firstRunKey, t.millisecondsSinceEpoch);
    return t;
  }

  static Future<int> totalAnalyses() => _count(_totalKey);

  static Future<int> used({DateTime? now}) async =>
      (await SharedPreferences.getInstance())
          .getInt(_monthKey(now ?? DateTime.now())) ??
      0;

  /// Extra analyses earned by watching a rewarded ad. They do not expire.
  static Future<int> bonus() async =>
      (await SharedPreferences.getInstance()).getInt(_bonusKey) ?? 0;

  static Future<void> addBonus([int count = 1]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bonusKey, (prefs.getInt(_bonusKey) ?? 0) + count);
  }

  /// Analyses left on the free plan: this month's allowance plus any bonus
  /// (never negative).
  static Future<int> remaining({DateTime? now}) async {
    final monthly = freeMonthlyAnalyses - await used(now: now);
    return (monthly < 0 ? 0 : monthly) + await bonus();
  }

  static Future<bool> canAnalyze({DateTime? now}) async =>
      await remaining(now: now) > 0;

  /// Counts one successful analysis. The monthly allowance is used first,
  /// then earned bonus analyses.
  static Future<void> recordAnalysis({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalKey, (prefs.getInt(_totalKey) ?? 0) + 1);
    final key = _monthKey(now ?? DateTime.now());
    final usedNow = prefs.getInt(key) ?? 0;
    final bonusNow = prefs.getInt(_bonusKey) ?? 0;
    if (usedNow >= freeMonthlyAnalyses && bonusNow > 0) {
      await prefs.setInt(_bonusKey, bonusNow - 1);
    } else {
      await prefs.setInt(key, usedNow + 1);
    }
  }

  static String _dayKey(String kind, DateTime now) =>
      'daily_${kind}_${now.year}_${now.month}_${now.day}';

  /// Whether one more [kind] ('analysis' or 'ask', where comparisons count as
  /// 'ask') is allowed today.
  static Future<bool> canUseDaily(String kind, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final day = now ?? DateTime.now();
    final used = prefs.getInt(_dayKey(kind, day)) ?? 0;
    final extra = prefs.getInt(_adDayKey('askbonus', day)) ?? 0;
    return used < (kind == 'ask' ? freeDailyQuestions + extra : 1 << 30);
  }

  static Future<void> recordDaily(String kind, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _dayKey(kind, now ?? DateTime.now());
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
  }
}
