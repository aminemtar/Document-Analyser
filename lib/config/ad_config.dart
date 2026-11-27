import 'dart:io' show Platform;

/// AdMob setup.
///
/// Out of the box the app uses Google's official TEST ad units, so you can
/// run it and click ads safely. To go live:
///  1. Create the app and ad units in AdMob.
///  2. Replace the test APPLICATION_ID in AndroidManifest.xml and
///     GADApplicationIdentifier in Info.plist with your real app id.
///  3. Build with your unit ids, e.g.
///     flutter build appbundle --dart-define=ADS_LIVE=true \
///       --dart-define=ADMOB_ANDROID_BANNER=ca-app-pub-.../... (and the others)
///
/// Never click your own live ads; it can get the AdMob account suspended.
abstract final class AdConfig {
  static const live = bool.fromEnvironment('ADS_LIVE');

  // Google's published test units.
  static const _testBanner = (
    android: 'ca-app-pub-3940256099942544/6300978111',
    ios: 'ca-app-pub-3940256099942544/2934735716'
  );
  static const _testInterstitial = (
    android: 'ca-app-pub-3940256099942544/1033173712',
    ios: 'ca-app-pub-3940256099942544/4411468910'
  );
  static const _testRewarded = (
    android: 'ca-app-pub-3940256099942544/5224354917',
    ios: 'ca-app-pub-3940256099942544/1712485313'
  );

  static const _liveBanner = (
    android: String.fromEnvironment('ADMOB_ANDROID_BANNER'),
    ios: String.fromEnvironment('ADMOB_IOS_BANNER')
  );
  static const _liveInterstitial = (
    android: String.fromEnvironment('ADMOB_ANDROID_INTERSTITIAL'),
    ios: String.fromEnvironment('ADMOB_IOS_INTERSTITIAL')
  );
  static const _liveRewarded = (
    android: String.fromEnvironment('ADMOB_ANDROID_REWARDED'),
    ios: String.fromEnvironment('ADMOB_IOS_REWARDED')
  );

  static String _pick(({String android, String ios}) test,
      ({String android, String ios}) real) {
    final ids = live ? real : test;
    return Platform.isIOS ? ids.ios : ids.android;
  }

  static String get banner => _pick(_testBanner, _liveBanner);
  static String get interstitial => _pick(_testInterstitial, _liveInterstitial);
  static String get rewarded => _pick(_testRewarded, _liveRewarded);
}
