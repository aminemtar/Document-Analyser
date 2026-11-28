import 'dart:io' show Platform;

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AdMob IDs are loaded from the local, git-ignored .env file.
/// If an ID is absent, Google's official test unit is used instead.
abstract final class AdConfig {
  static String _id(String key, String fallback) {
    final value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? fallback : value;
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
