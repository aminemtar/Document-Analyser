import 'package:flutter/material.dart' hide Text;
import '../l10n/tr_text.dart';
import '../services/usage_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/common.dart';
import '../services/ad_service.dart';
import '../l10n/locale_controller.dart';
import '../widgets/language_sheet.dart';
import 'more_analyses_page.dart';

class ProfilePage extends StatelessWidget {
  final bool remindersEnabled;
  final ValueChanged<bool> onRemindersChanged;
  final VoidCallback onBackup;
  final VoidCallback onRestore;
  const ProfilePage(
      {super.key,
      required this.remindersEnabled,
      required this.onRemindersChanged,
      required this.onBackup,
      required this.onRestore});

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
        const _LanguageRow(),
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
        sectionTitle('Your data'),
        Card(
            margin: const EdgeInsets.only(bottom: 9),
            child: ListTile(
                leading: Icon(Icons.cloud_upload_outlined, color: blue),
                title: Text('Back up analyses',
                    style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                subtitle: Text(
                    'Save your library and analyses to a file (original files are not included)',
                    style: TextStyle(color: muted, fontSize: 12)),
                onTap: onBackup)),
        Card(
            margin: const EdgeInsets.only(bottom: 9),
            child: ListTile(
                leading: Icon(Icons.settings_backup_restore_rounded,
                    color: blue),
                title: Text('Restore from backup',
                    style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                subtitle: Text('Add analyses from a DocuMind backup file',
                    style: TextStyle(color: muted, fontSize: 12)),
                onTap: onRestore)),
        const _AdPrivacyRow(),
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
/// opens the "get more analyses" page and refreshes when the user comes back.
class _PlanCard extends StatefulWidget {
  const _PlanCard();
  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  int left = UsageService.freeMonthlyAnalyses;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final remaining = await UsageService.remaining();
    if (mounted) {
      setState(() {
        left = remaining;
      });
    }
  }

  Future<void> _open() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MoreAnalysesPage()));
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
              const Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Free plan',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                        '$left ${left == 1 ? 'analysis' : 'analyses'} left ($total free each month)',
                        style: const TextStyle(
                            color: Color(0xFFDCE6FF), fontSize: 13)),
                  ])),
              Text('Get more',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ])));
  }
}

/// "Ad privacy choices": only shown where the consent form is required
/// (for example the EU and UK), as the rules ask.
class _AdPrivacyRow extends StatefulWidget {
  const _AdPrivacyRow();
  @override
  State<_AdPrivacyRow> createState() => _AdPrivacyRowState();
}

class _AdPrivacyRowState extends State<_AdPrivacyRow> {
  bool required = false;

  @override
  void initState() {
    super.initState();
    AdService.privacyOptionsRequired().then((v) {
      if (mounted) setState(() => required = v);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    if (!required) return const SizedBox.shrink();
    return Card(
        margin: const EdgeInsets.only(bottom: 9),
        child: ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: blue),
            title: Text('Ad privacy choices',
                style: TextStyle(
                    color: navy, fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text('Change your consent for personalized ads',
                style: TextStyle(color: muted, fontSize: 12)),
            onTap: AdService.showPrivacyOptions));
  }
}

/// Language picker: system default, English, Français or العربية.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
      valueListenable: LocaleController.choice,
      builder: (context, choice, _) {
        final name = choice == 'system' ? 'System'.tr : languageNames[choice]!;
        return Card(
            margin: const EdgeInsets.only(bottom: 9),
            child: ListTile(
                leading: Icon(Icons.language_rounded, color: blue),
                title: Text('Language',
                    style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                subtitle: Text(
                    '$name. ${'Scanning cannot read Arabic yet'.tr}',
                    style: TextStyle(color: muted, fontSize: 12)),
                trailing: Text(L10n.language.value.toUpperCase(),
                    style: TextStyle(color: muted, fontSize: 14)),
                onTap: () => showLanguageSheet(context)));
      });
}
