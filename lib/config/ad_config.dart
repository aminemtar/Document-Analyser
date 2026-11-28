import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Keep test ads enabled during development and Google Play Closed Testing.
/// Set useTestAds to false only when the public production release is ready.
abstract final class AdConfig {
  static const bool useTestAds = true;

  static String _id(String key, String testId) {
    if (useTestAds || !kReleaseMode) return testId;
    final value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? testId : value;
  }

  static String get banner => Platform.isIOS
      ? _id('ADMOB_IOS_BANNER', 'ca-app-pub-3940256099942544/2934735716')
      : _id('ADMOB_ANDROID_BANNER', 'ca-app-pub-3940256099942544/6300978111');

  static String get interstitial => Platform.isIOS
      ? _id('ADMOB_IOS_INTERSTITIAL', 'ca-app-pub-3940256099942544/4411468910')
      : _id('ADMOB_ANDROID_INTERSTITIAL', 'ca-app-pub-3940256099942544/1033173712');

  static String get rewarded => Platform.isIOS
      ? _id('ADMOB_IOS_REWARDED', 'ca-app-pub-3940256099942544/1712485313')
      : _id('ADMOB_ANDROID_REWARDED', 'ca-app-pub-3940256099942544/5224354917');
}
