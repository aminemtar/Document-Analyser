import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import '../l10n/l10n.dart';
import '../l10n/locale_controller.dart';
import '../l10n/tr_text.dart';
import '../theme/app_theme.dart';

/// Opens the language chooser: system default, English, Français, العربية.
Future<void> showLanguageSheet(BuildContext context) async {
  final current = LocaleController.choice.value;
  final picked = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('Choose language',
                  style: TextStyle(
                      color: navy, fontWeight: FontWeight.w800, fontSize: 18))),
          const SizedBox(height: 12),
          for (final code in const ['system', 'en', 'fr', 'ar'])
            _LanguageOption(
                code: code,
                selected: code == current,
                onTap: () => Navigator.of(sheetContext).pop(code)),
        ]),
      ),
    ),
  );
  if (picked != null && picked != current) {
    HapticFeedback.selectionClick();
    await LocaleController.set(picked);
  }
}

class _LanguageOption extends StatelessWidget {
  final String code;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageOption(
      {required this.code, required this.selected, required this.onTap});

  String get _monogram => switch (code) {
        'en' => 'EN',
        'fr' => 'FR',
        'ar' => 'ع',
        _ => 'A',
      };

  @override
  Widget build(BuildContext context) {
    final name = code == 'system' ? 'System'.tr : languageNames[code]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: selected ? AppColors.accentSoft : AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: selected ? blue : AppColors.border)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(colors: AppColors.heroGradient)
                          : null,
                      color: selected ? null : AppColors.surfaceTint,
                      borderRadius: BorderRadius.circular(13)),
                  child: code == 'system'
                      ? Icon(Icons.smartphone_rounded,
                          size: 20, color: selected ? Colors.white : blue)
                      : Text(_monogram,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: selected ? Colors.white : blue))),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(name,
                      style: TextStyle(
                          color: navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 15))),
              if (selected) Icon(Icons.check_circle_rounded, color: blue),
            ]),
          ),
        ),
      ),
    );
  }
}
