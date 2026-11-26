import 'package:flutter/material.dart';
import '../services/usage_service.dart';
import '../theme/app_theme.dart';

/// Example prices, only used to design the screen. Replace them with the
/// store's real localized prices when billing is connected.
const _monthlyPrice = '\$4.99';
const _yearlyPrice = '\$39.99';

/// Whether real purchases are wired up. While false, the button only flips a
/// local preview flag and the screen says so.
const billingConnected = false;

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});
  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool yearly = true;
  bool isPro = false;

  @override
  void initState() {
    super.initState();
    UsageService.isPro().then((v) {
      if (mounted) setState(() => isPro = v);
    });
  }

  Future<void> _primary() async {
    await UsageService.setPro(!isPro);
    if (mounted) Navigator.of(context).pop();
  }

  Widget _benefit(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: blue, size: 18)),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: navy, fontSize: 14, fontWeight: FontWeight.w600))),
      ]));

  Widget _plan(
      {required bool selected,
      required String title,
      required String price,
      required String note,
      String? badge,
      required VoidCallback onTap}) {
    return InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
                color: selected ? AppColors.surfaceTint : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: selected ? blue : const Color(0xFFDDE3F0),
                    width: selected ? 2 : 1)),
            child: Row(children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? blue : muted),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Text(title,
                          style: const TextStyle(
                              color: navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(badge,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800))),
                      ],
                    ]),
                    Text(note,
                        style: const TextStyle(color: muted, fontSize: 12)),
                  ])),
              Text(price,
                  style: const TextStyle(
                      color: navy, fontSize: 16, fontWeight: FontWeight.w800)),
            ])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              tooltip: 'Close',
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
                      Icon(Icons.workspace_premium_rounded,
                          color: Colors.white, size: 34),
                      SizedBox(height: 12),
                      Text('DocuMind Pro',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.6)),
                      SizedBox(height: 6),
                      Text(
                          'Analyze as many documents as you need and never miss a date.',
                          style: TextStyle(
                              color: Color(0xFFDCE6FF),
                              fontSize: 14,
                              height: 1.45)),
                    ])),
            const SizedBox(height: 18),
            _benefit(Icons.all_inclusive_rounded, 'Unlimited analyses every month'),
            _benefit(Icons.event_available_rounded, 'Date and deadline reminders'),
            _benefit(Icons.chat_bubble_outline_rounded,
                'Unlimited assistant questions'),
            _benefit(Icons.compare_arrows_rounded, 'Compare documents side by side'),
            const SizedBox(height: 14),
            if (!isPro) ...[
              _plan(
                  selected: yearly,
                  title: 'Yearly',
                  price: _yearlyPrice,
                  note: 'Best value, billed once a year',
                  badge: 'SAVE 33%',
                  onTap: () => setState(() => yearly = true)),
              _plan(
                  selected: !yearly,
                  title: 'Monthly',
                  price: _monthlyPrice,
                  note: 'Cancel any time',
                  onTap: () => setState(() => yearly = false)),
            ],
            if (!billingConnected)
              Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: const Text(
                      'Preview: purchases are not connected yet. Nothing is charged, and the prices shown are examples.',
                      style: TextStyle(
                          color: AppColors.warning, fontSize: 12, height: 1.4))),
            SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: _primary,
                    style: FilledButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(
                        isPro
                            ? 'Switch back to Free (preview)'
                            : 'Unlock Pro (preview)',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)))),
            const SizedBox(height: 6),
            Center(
                child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Not now',
                        style: TextStyle(color: muted)))),
            const Center(
                child: Text(
                    'Free plan: ${UsageService.freeMonthlyAnalyses} analyses per month.',
                    style: TextStyle(color: muted, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}
