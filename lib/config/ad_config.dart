import 'dart:io' show Platform;

/// Keep test ads enabled during development and Google Play Closed Testing.
/// Set this to false only when the public production release is ready.
abstract final class AdConfig {
  static const bool useTestAds = true;

  static String _id(String productionKey, String testId) {
    if (useTestAds) return testId;
    // Production IDs are read from .env only after explicitly enabling them.
    return testId;
  }

  static String get banner => Platform.isIOS
      ? _id('ADMOB_IOS_BANNER', 'ca-app-pub-3940256099942544/2934735716')
      : _id('ADMOB_ANDROID_BANNER', 'ca-app-pub-3940258099942544/6300978111');

  static String get interstitial => Platform.isIOS
      ? _id('ADMOB_IOS_INTERSTITIAL', 'ca-app-pub-3940256099942544/4411468910')
      : _id('ADMOB_ANDROID_INTERSTITIAL', 'ca-app-pub-3940256099942544/1033173712');

  static String get rewarded => Platform.isIOS
      ? _id('ADMOB_IOS_REWARDED', 'ca-app-pub-3940256099942544/1712485313')
      : _id('ADMOB_ANDROID_REWARDED', 'ca-app-pub-3940256099942544/5224354917');
}
