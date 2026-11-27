import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'usage_service.dart';

/// Pro subscriptions. Create these two subscription products with exactly
/// these ids in Google Play Console and App Store Connect.
const proMonthlyId = 'documind_pro_monthly';
const proYearlyId = 'documind_pro_yearly';
const proProductIds = {proMonthlyId, proYearlyId};

/// How long a Pro unlock is trusted without the store confirming it again.
const proRecheckAfter = Duration(days: 7);

/// Whether a locally stored Pro flag should be dropped. The store is asked
/// to restore purchases on every launch; if it is reachable but has not
/// confirmed an active subscription for [proRecheckAfter], Pro has lapsed
/// (cancelled, refunded or expired). Pure, so it can be tested.
bool shouldRevokePro({
  required bool isPro,
  required bool storeAvailable,
  required DateTime? lastConfirmed,
  required DateTime now,
}) {
  if (!isPro || !storeAvailable) return false;
  if (lastConfirmed == null) return true;
  return now.difference(lastConfirmed) > proRecheckAfter;
}

/// Store billing through the platform's official in-app purchase API.
///
/// Limits: purchases are trusted as reported by the store on the device.
/// Without a server there is no receipt validation, so a rooted device
/// could fake them. That is an accepted trade-off while the app has no
/// backend.
abstract final class BillingService {
  static const _confirmedKey = 'pro_confirmed_at';

  /// Products loaded from the store (empty until loaded or if unavailable).
  static final ValueNotifier<List<ProductDetails>> products =
      ValueNotifier(const []);

  /// True while a purchase or restore is in progress.
  static final ValueNotifier<bool> busy = ValueNotifier(false);

  /// Latest message for the paywall (errors, "restored", "no purchases").
  static final ValueNotifier<String?> message = ValueNotifier(null);

  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static bool _storeAvailable = false;

  static bool get supported =>
      !kIsWeb &&
      (Platform.isAndroid || Platform.isIOS) &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  static bool get storeAvailable => _storeAvailable;

  static ProductDetails? product(String id) {
    for (final p in products.value) {
      if (p.id == id) return p;
    }
    return null;
  }

  static Future<void> init() async {
    if (!supported || _subscription != null) return;
    try {
      final iap = InAppPurchase.instance;
      _subscription = iap.purchaseStream.listen(_onPurchases,
          onError: (Object e) => message.value = 'Purchase error: $e');
      _storeAvailable = await iap.isAvailable();
      if (!_storeAvailable) return;
      await loadProducts();
      await iap.restorePurchases();
      // Give the store a moment to report, then re-check the Pro flag.
      unawaited(Future<void>.delayed(const Duration(seconds: 10), _recheck));
    } catch (e) {
      debugPrint('Billing unavailable: $e');
    }
  }

  static Future<void> loadProducts() async {
    final response = await InAppPurchase.instance.queryProductDetails(proProductIds);
    products.value = response.productDetails;
    if (response.productDetails.isEmpty) {
      message.value =
          'Subscriptions are not available yet. Check your connection and try again.';
    }
  }

  static Future<void> buy(ProductDetails details) async {
    if (busy.value) return;
    busy.value = true;
    message.value = null;
    try {
      final started = await InAppPurchase.instance
          .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: details));
      if (!started) busy.value = false;
    } catch (e) {
      busy.value = false;
      message.value = 'Could not start the purchase: $e';
    }
  }

  static Future<void> restore() async {
    if (!supported || !_storeAvailable) {
      message.value = 'The store is not available on this device.';
      return;
    }
    busy.value = true;
    message.value = null;
    try {
      await InAppPurchase.instance.restorePurchases();
      // The result arrives on the purchase stream. If nothing comes back,
      // tell the user instead of leaving a spinner.
      unawaited(Future<void>.delayed(const Duration(seconds: 6), () {
        if (busy.value) {
          busy.value = false;
          if (!UsageService.proNotifier.value) {
            message.value = 'No active subscription was found for this account.';
          }
        }
      }));
    } catch (e) {
      busy.value = false;
      message.value = 'Could not restore purchases: $e';
    }
  }

  static Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          busy.value = true;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (proProductIds.contains(purchase.productID)) {
            await _confirm();
            message.value = purchase.status == PurchaseStatus.restored
                ? 'Your Pro plan was restored.'
                : 'Welcome to Pro!';
          }
          busy.value = false;
        case PurchaseStatus.error:
          busy.value = false;
          message.value = purchase.error?.message ?? 'The purchase failed.';
        case PurchaseStatus.canceled:
          busy.value = false;
      }
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }

  static Future<void> _confirm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_confirmedKey, DateTime.now().millisecondsSinceEpoch);
    await UsageService.setPro(true);
  }

  static Future<void> _recheck() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_confirmedKey);
    if (shouldRevokePro(
      isPro: await UsageService.isPro(),
      storeAvailable: _storeAvailable,
      lastConfirmed: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
      now: DateTime.now(),
    )) {
      await UsageService.setPro(false);
    }
  }
}
