import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';
import '../services/ad_service.dart';
import '../services/usage_service.dart';

/// A small banner shown to free users. Takes no space until an ad has
/// loaded, in tests, on unsupported platforms.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    AdService.ready.addListener(_maybeLoad);
    UsageService.adFreeNotifier.addListener(_onAdFreeChanged);
    _maybeLoad();
  }

  void _onAdFreeChanged() {
    if (UsageService.adFreeNotifier.value) {
      _ad?.dispose();
      _ad = null;
      _loaded = false;
      if (mounted) setState(() {});
    } else {
      _maybeLoad();
    }
  }

  bool _loading = false;

  Future<void> _maybeLoad() async {
    if (_ad != null ||
        _loading ||
        !AdService.adsAllowed ||
        !AdService.ready.value) {
      return;
    }
    _loading = true;
    // An adaptive banner fills the width of the screen. It gets better ads
    // and looks cleaner than a small fixed banner.
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final width = (view.physicalSize.width / view.devicePixelRatio).truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            width) ??
        AdSize.banner;
    _loading = false;
    if (!mounted || _ad != null || !AdService.adsAllowed) return;
    final ad = BannerAd(
      adUnitId: AdConfig.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    AdService.ready.removeListener(_maybeLoad);
    UsageService.adFreeNotifier.removeListener(_onAdFreeChanged);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded) {
      return const SizedBox.shrink();
    }
    return SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad));
  }
}
