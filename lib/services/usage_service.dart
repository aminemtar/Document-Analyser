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

  static String _monthKey(DateTime now) => 'usage_${now.year}_${now.month}';

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
    final used = prefs.getInt(_dayKey(kind, now ?? DateTime.now())) ?? 0;
    return used < (kind == 'ask' ? freeDailyQuestions : 1 << 30);
  }

  static Future<void> recordDaily(String kind, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _dayKey(kind, now ?? DateTime.now());
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
  }
}
