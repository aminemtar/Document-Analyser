import 'package:documind_ai/services/usage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final june = DateTime(2026, 6, 15);
  final july = DateTime(2026, 7, 1);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('free plan allows three analyses, then blocks', () async {
    for (var i = 0; i < UsageService.freeMonthlyAnalyses; i++) {
      expect(await UsageService.canAnalyze(now: june), isTrue);
      await UsageService.recordAnalysis(now: june);
    }
    expect(await UsageService.remaining(now: june), 0);
    expect(await UsageService.canAnalyze(now: june), isFalse);
  });

  test('the allowance resets in a new month', () async {
    for (var i = 0; i < UsageService.freeMonthlyAnalyses; i++) {
      await UsageService.recordAnalysis(now: june);
    }
    expect(await UsageService.canAnalyze(now: july), isTrue);
    expect(await UsageService.remaining(now: july),
        UsageService.freeMonthlyAnalyses);
  });

  test('Pro is never blocked', () async {
    for (var i = 0; i < 5; i++) {
      await UsageService.recordAnalysis(now: june);
    }
    await UsageService.setPro(true);
    expect(await UsageService.canAnalyze(now: june), isTrue);
    await UsageService.setPro(false);
    expect(await UsageService.canAnalyze(now: june), isFalse);
  });
}
