import 'package:documind_ai/services/ad_service.dart';
import 'package:documind_ai/services/billing_service.dart';
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

  group('Pro re-check', () {
    final now = DateTime(2026, 11, 27);

    test('a recently confirmed Pro stays Pro', () {
      expect(
          shouldRevokePro(
              isPro: true,
              storeAvailable: true,
              lastConfirmed: now.subtract(const Duration(days: 2)),
              now: now),
          isFalse);
    });

    test('Pro not confirmed for over a week is dropped', () {
      expect(
          shouldRevokePro(
              isPro: true,
              storeAvailable: true,
              lastConfirmed: now.subtract(const Duration(days: 8)),
              now: now),
          isTrue);
    });

    test('an old flag with no confirmation at all is dropped', () {
      expect(
          shouldRevokePro(
              isPro: true, storeAvailable: true, lastConfirmed: null, now: now),
          isTrue);
    });

    test('offline or free users are never changed', () {
      expect(
          shouldRevokePro(
              isPro: true,
              storeAvailable: false,
              lastConfirmed: null,
              now: now),
          isFalse);
      expect(
          shouldRevokePro(
              isPro: false,
              storeAvailable: true,
              lastConfirmed: null,
              now: now),
          isFalse);
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

    test('the Pro notifier follows setPro', () async {
      await UsageService.setPro(true);
      expect(UsageService.proNotifier.value, isTrue);
      await UsageService.setPro(false);
      expect(UsageService.proNotifier.value, isFalse);
    });
  });

  test('ads and billing stay off outside a phone (tests, desktop)', () {
    expect(AdService.supported, isFalse);
    expect(BillingService.supported, isFalse);
    expect(AdService.adsAllowed, isFalse);
  });
}
