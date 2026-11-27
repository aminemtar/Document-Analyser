import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Free-plan limit, bonus analyses and Pro flag, stored on the device only.
///
/// The Pro flag is set from the store purchase (see BillingService), but the
/// limit itself is local: clearing the app data resets it. A hard limit needs
/// a server to enforce it.
abstract final class UsageService {
  static const freeMonthlyAnalyses = 3;
  static const _proKey = 'plan_pro_preview';
  static const _bonusKey = 'bonus_analyses';

  static String _monthKey(DateTime now) => 'usage_${now.year}_${now.month}';

  /// Live Pro state, so ads and screens react as soon as it changes.
  static final ValueNotifier<bool> proNotifier = ValueNotifier(false);

  static Future<bool> isPro() async {
    final value =
        (await SharedPreferences.getInstance()).getBool(_proKey) ?? false;
    proNotifier.value = value;
    return value;
  }

  static Future<void> setPro(bool value) async {
    await (await SharedPreferences.getInstance()).setBool(_proKey, value);
    proNotifier.value = value;
  }

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
      await isPro() || await remaining(now: now) > 0;

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
}
