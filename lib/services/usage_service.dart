import 'package:shared_preferences/shared_preferences.dart';

/// Free-plan limit and Pro flag, stored on the device only.
///
/// This is a design and flow preview: anyone can clear the app data to reset
/// it, and nothing here takes payment. A real limit needs a server (or store
/// receipts) to enforce it.
abstract final class UsageService {
  static const freeMonthlyAnalyses = 3;
  static const _proKey = 'plan_pro_preview';

  static String _monthKey(DateTime now) => 'usage_${now.year}_${now.month}';

  static Future<bool> isPro() async =>
      (await SharedPreferences.getInstance()).getBool(_proKey) ?? false;

  static Future<void> setPro(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_proKey, value);

  static Future<int> used({DateTime? now}) async =>
      (await SharedPreferences.getInstance())
          .getInt(_monthKey(now ?? DateTime.now())) ??
      0;

  /// Analyses left this month on the free plan (never negative).
  static Future<int> remaining({DateTime? now}) async {
    final left = freeMonthlyAnalyses - await used(now: now);
    return left < 0 ? 0 : left;
  }

  static Future<bool> canAnalyze({DateTime? now}) async =>
      await isPro() || await remaining(now: now) > 0;

  /// Counts one successful analysis against this month.
  static Future<void> recordAnalysis({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _monthKey(now ?? DateTime.now());
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
  }
}
