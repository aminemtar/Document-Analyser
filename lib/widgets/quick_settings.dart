import 'package:flutter/material.dart' hide Text;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../l10n/l10n.dart';
import '../l10n/tr_text.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import 'language_sheet.dart';

/// Language and light/dark switches for the app bar, so both are one tap
/// away from any screen instead of hidden in Profile.
List<Widget> quickSettingsActions(BuildContext context) => const [
      LanguagePill(),
      SizedBox(width: 2),
      ThemeToggleButton(),
      SizedBox(width: 6),
    ];

/// A small pill showing the current language (EN, FR, ع) that opens the
/// language chooser.
class LanguagePill extends StatelessWidget {
  const LanguagePill({super.key});

  @override
  Widget build(BuildContext context) {
    final label = switch (L10n.language.value) { 'ar' => 'ع', final c => c.toUpperCase() };
    return Semantics(
      button: true,
      label: 'Language'.tr,
      child: ExcludeSemantics(
        child: Tooltip(
          message: 'Language'.tr,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => showLanguageSheet(context),
            child: Container(
              constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.language_rounded, size: 16, color: blue),
                  const SizedBox(width: 5),
                  Text(label,
                      style: TextStyle(
                          color: navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sun/moon button: switches between light and dark with a small turn
/// animation. Choosing it sets the appearance explicitly (Profile can set it
/// back to "System").
class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton> {
  /// Remembers where this button is, so the theme animation can start there.
  void _registerPosition() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.attached && box.hasSize) {
      ThemeController.toggleCenter =
          box.localToGlobal(box.size.center(Offset.zero));
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerPosition());
    final dark = AppPalette.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final label = dark ? 'Switch to light mode' : 'Switch to dark mode';
    return IconButton(
      tooltip: label.tr,
      onPressed: () {
        HapticFeedback.selectionClick();
        _registerPosition();
        ThemeController.set(dark ? ThemeMode.light : ThemeMode.dark);
      },
      icon: AnimatedSwitcher(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
        transitionBuilder: (child, animation) => RotationTransition(
            turns: Tween<double>(begin: .75, end: 1).animate(animation),
            child: FadeTransition(opacity: animation, child: child)),
        child: Icon(
            dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            key: ValueKey(dark),
            color: dark ? const Color(0xFFFFC857) : blue),
      ),
    );
  }
}
