import 'package:flutter/material.dart';
import '../services/usage_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/common.dart';
import 'paywall_page.dart';

class ProfilePage extends StatelessWidget {
  final bool remindersEnabled;
  final ValueChanged<bool> onRemindersChanged;
  const ProfilePage(
      {super.key,
      required this.remindersEnabled,
      required this.onRemindersChanged});

  @override
  Widget build(BuildContext context) => PageBody(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading('Your profile', 'Manage your workspace preferences.'),
        const SizedBox(height: 22),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                color: AppColors.surface, borderRadius: BorderRadius.circular(22)),
            child: Column(children: [
              CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.accentSoft,
                  child: Text('M',
                      style: TextStyle(
                          color: blue,
                          fontSize: 27,
                          fontWeight: FontWeight.w800))),
              SizedBox(height: 12),
              Text('My workspace',
                  style: TextStyle(
                      color: navy, fontWeight: FontWeight.w800, fontSize: 17)),
              SizedBox(height: 4),
              Text('Personal account',
                  style: TextStyle(color: muted, fontSize: 13)),
            ])),
        const SizedBox(height: 14),
        const _PlanCard(),
        sectionTitle('Preferences'),
        const SettingsRow(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: 'English',
            trailing: 'EN'),
        Card(
            margin: const EdgeInsets.only(bottom: 9),
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.dark_mode_outlined, color: blue),
                        const SizedBox(width: 16),
                        Text('Appearance',
                            style: TextStyle(
                                color: navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ]),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<ThemeMode>(
                          valueListenable: ThemeController.mode,
                          builder: (context, mode, _) => SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<ThemeMode>(
                                  showSelectedIcon: false,
                                  segments: const [
                                    ButtonSegment(
                                        value: ThemeMode.system,
                                        label: Text('System')),
                                    ButtonSegment(
                                        value: ThemeMode.light,
                                        label: Text('Light')),
                                    ButtonSegment(
                                        value: ThemeMode.dark,
                                        label: Text('Dark')),
                                  ],
                                  selected: {mode},
                                  onSelectionChanged: (selection) =>
                                      ThemeController.set(selection.first)))),
                    ]))),
        Card(
            margin: const EdgeInsets.only(bottom: 9),
            child: SwitchListTile(
                secondary: Icon(Icons.notifications_none_rounded,
                    color: blue),
                title: Text('Date reminders',
                    style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                subtitle: Text(
                    'A notification at 9:00 the day before and on the day of dates found in your documents',
                    style: TextStyle(color: muted, fontSize: 12)),
                value: remindersEnabled,
                onChanged: onRemindersChanged)),
        const SettingsRow(
            icon: Icons.lock_outline_rounded,
            title: 'Privacy & security',
            subtitle: 'Your files stay in your workspace'),
        const SettingsRow(
            icon: Icons.help_outline_rounded,
            title: 'Help & support',
            subtitle: 'Get assistance'),
        const SizedBox(height: 18),
        Center(
            child: Text('DocuMind AI  ·  Version 1.0.0',
                style: TextStyle(color: muted, fontSize: 12))),
      ]));
}

/// Shows the current plan and what is left of the free allowance. Tapping it
/// opens the paywall and refreshes when the user comes back.
class _PlanCard extends StatefulWidget {
  const _PlanCard();
  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool isPro = false;
  int left = UsageService.freeMonthlyAnalyses;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final pro = await UsageService.isPro();
    final remaining = await UsageService.remaining();
    if (mounted) {
      setState(() {
        isPro = pro;
        left = remaining;
      });
    }
  }

  Future<void> _open() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PaywallPage()));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    const total = UsageService.freeMonthlyAnalyses;
    return InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: _open,
        child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.heroGradient),
                borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(isPro ? 'Pro plan (preview)' : 'Free plan',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                        isPro
                            ? 'Unlimited analyses'
                            : '$left of $total analyses left this month',
                        style: const TextStyle(
                            color: Color(0xFFDCE6FF), fontSize: 13)),
                  ])),
              Text(isPro ? 'Manage' : 'Upgrade',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ])));
  }
}
