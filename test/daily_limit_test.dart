import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:documind_ai/services/usage_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('free users get a daily question cap that resets next day', () async {
    final day = DateTime(2026, 11, 27, 10);
    for (var i = 0; i < UsageService.freeDailyQuestions; i++) {
      expect(await UsageService.canUseDaily('ask', now: day), isTrue);
      await UsageService.recordDaily('ask', now: day);
    }
    expect(await UsageService.canUseDaily('ask', now: day), isFalse);
    expect(
        await UsageService.canUseDaily('ask', now: day.add(const Duration(days: 1))),
        isTrue);
  });
}
