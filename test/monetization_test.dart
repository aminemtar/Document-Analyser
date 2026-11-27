import 'package:documind_ai/services/ad_service.dart';
import 'package:documind_ai/services/usage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('interstitial pacing', () {
    final now = DateTime(2026, 11, 27, 12);

    test('waits for two completed analyses', () {
      expect(
          shouldShowInterstitial(
              analysesSinceLastAd: 1, lastShown: null, now: now),
          isFalse);
      expect(
          shouldShowInterstitial(
              analysesSinceLastAd: 2, lastShown: null, now: now),
          isTrue);
    });

    test('never twice within three minutes', () {
      expect(
          shouldShowInterstitial(
              analysesSinceLastAd: 5,
              lastShown: now.subtract(const Duration(minutes: 2)),
              now: now),
          isFalse);
      expect(
          shouldShowInterstitial(
              analysesSinceLastAd: 5,
              lastShown: now.subtract(const Duration(minutes: 4)),
              now: now),
          isTrue);
    });
  });

  group('bonus analyses from rewarded ads', () {
    final june = DateTime(2026, 6, 15);
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a bonus lets a user past the monthly limit, once', () async {
      for (var i = 0; i < UsageService.freeMonthlyAnalyses; i++) {
        await UsageService.recordAnalysis(now: june);
      }
      expect(await UsageService.canAnalyze(now: june), isFalse);
      await UsageService.addBonus();
      expect(await UsageService.remaining(now: june), 1);
      expect(await UsageService.canAnalyze(now: june), isTrue);
      await UsageService.recordAnalysis(now: june);
      expect(await UsageService.canAnalyze(now: june), isFalse);
      expect(await UsageService.bonus(), 0);
    });

    test('the monthly allowance is spent before the bonus', () async {
      await UsageService.addBonus(2);
      await UsageService.recordAnalysis(now: june);
      expect(await UsageService.bonus(), 2);
      expect(await UsageService.remaining(now: june),
          UsageService.freeMonthlyAnalyses - 1 + 2);
    });
  });

  test('ads stay off outside a phone (tests, desktop)', () {
    expect(AdService.supported, isFalse);
    expect(AdService.adsAllowed, isFalse);
  });

  group('smart interstitial rules', () {
    final now = DateTime(2026, 11, 27, 12);
    bool show({
      int total = 10,
      DateTime? firstRun,
      int today = 0,
    }) =>
        shouldShowInterstitial(
            analysesSinceLastAd: 2,
            lastShown: null,
            now: now,
            totalAnalyses: total,
            firstRun: firstRun,
            shownToday: today);

    test('not before the third analysis', () {
      expect(show(total: 2), isFalse);
      expect(show(total: 3), isTrue);
    });

    test('not during the first day after install', () {
      expect(show(firstRun: now.subtract(const Duration(hours: 5))), isFalse);
      expect(show(firstRun: now.subtract(const Duration(hours: 30))), isTrue);
    });

    test('at most three a day', () {
      expect(show(today: 2), isTrue);
      expect(show(today: 3), isFalse);
    });
  });

  group('rewarded rewards', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    final day = DateTime(2026, 11, 27, 9);

    test('an ad-free period starts and ends', () async {
      expect(await UsageService.isAdFree(now: day), isFalse);
      await UsageService.grantAdFree(now: day);
      expect(await UsageService.isAdFree(now: day), isTrue);
      expect(UsageService.adFreeNotifier.value, isTrue);
      expect(await UsageService.isAdFree(now: day.add(const Duration(hours: 25))),
          isFalse);
    });

    test('rewarded ads are capped per day', () async {
      for (var i = 0; i < UsageService.maxRewardedPerDay; i++) {
        expect(await UsageService.canWatchRewarded(now: day), isTrue);
        await UsageService.recordRewarded(now: day);
      }
      expect(await UsageService.canWatchRewarded(now: day), isFalse);
      expect(
          await UsageService.canWatchRewarded(
              now: day.add(const Duration(days: 1))),
          isTrue);
    });

    test('a rewarded ad adds questions for that day only', () async {
      for (var i = 0; i < UsageService.freeDailyQuestions; i++) {
        await UsageService.recordDaily('ask', now: day);
      }
      expect(await UsageService.canUseDaily('ask', now: day), isFalse);
      await UsageService.addQuestionBonus(UsageService.questionBonusSize, day);
      expect(await UsageService.canUseDaily('ask', now: day), isTrue);
    });
  });
}
