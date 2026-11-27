import 'package:flutter/material.dart' hide Text;
import '../l10n/tr_text.dart';
import '../services/ad_service.dart';
import '../services/usage_service.dart';
import '../theme/app_theme.dart';

/// Shown when the free analyses are used up: watch a short ad to earn one more.
class MoreAnalysesPage extends StatefulWidget {
  const MoreAnalysesPage({super.key});
  @override
  State<MoreAnalysesPage> createState() => _MoreAnalysesPageState();
}

class _MoreAnalysesPageState extends State<MoreAnalysesPage> {
  @override
  void initState() {
    super.initState();
    AdService.rewardedReady.addListener(_refresh);
    _load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AdService.rewardedReady.removeListener(_refresh);
    super.dispose();
  }

  bool canWatch = true;
  bool adFree = false;

  Future<void> _load() async {
    final watch = await UsageService.canWatchRewarded();
    final free = await UsageService.isAdFree();
    if (mounted) {
      setState(() {
        canWatch = watch;
        adFree = free;
      });
    }
  }

  /// A rewarded ad is worth far more than a banner view, so one ad buys a
  /// full day without banners or pop-up ads.
  Future<void> _watchForAdFree() async {
    final earned = await AdService.showRewarded();
    if (!mounted || !earned) return;
    await UsageService.recordRewarded();
    await UsageService.grantAdFree();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('You earned 24 hours without banner or pop-up ads.'),
        behavior: SnackBarBehavior.floating));
    await _load();
  }

  Future<void> _watchAd() async {
    final earned = await AdService.showRewarded();
    if (!mounted) return;
    if (earned) {
      await UsageService.recordRewarded();
      await UsageService.addBonus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('You earned 1 extra analysis.'),
          behavior: SnackBarBehavior.floating));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              tooltip: 'Close'.tr,
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop())),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.heroGradient),
                    borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.play_circle_fill_rounded,
                          color: Colors.white, size: 34),
                      SizedBox(height: 12),
                      Text('Get more analyses',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.6)),
                      SizedBox(height: 6),
                      Text(
                          'Watch a short ad to earn one extra analysis, or come back next month for a fresh allowance.',
                          style: TextStyle(
                              color: Color(0xFFDCE6FF),
                              fontSize: 14,
                              height: 1.45)),
                    ])),
            const SizedBox(height: 18),
            if (!canWatch)
              Text('You have reached today’s limit of ad rewards. Come back tomorrow.',
                  style: TextStyle(color: muted, fontSize: 13, height: 1.4))
            else ...[
              SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                      onPressed: AdService.rewardedReady.value ? _watchAd : null,
                      style: FilledButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      label: Text(
                          AdService.rewardedReady.value
                              ? 'Watch an ad for 1 extra analysis'
                              : 'No ad available right now. Try again soon.',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)))),
              const SizedBox(height: 10),
              SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                      onPressed: AdService.rewardedReady.value && !adFree
                          ? _watchForAdFree
                          : null,
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      icon: const Icon(Icons.block_rounded),
                      label: Text(adFree
                          ? 'Ads are paused for you right now'
                          : 'Watch an ad: no banner or pop-up ads for 24 hours'))),
            ],
            const SizedBox(height: 6),
            Center(
                child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Not now', style: TextStyle(color: muted)))),
            Center(
                child: Text(
                    'Free plan: ${UsageService.freeMonthlyAnalyses} analyses per month.',
                    style: TextStyle(color: muted, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}
