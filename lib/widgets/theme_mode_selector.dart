import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import '../l10n/tr_text.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

/// Premium appearance chooser: three cards with a small preview of each look.
/// The selected card uses the app's own accent colour and surface, so it
/// follows the theme in light and dark mode.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) => Row(children: [
        for (final (i, option) in _options.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
              child: _ModeCard(
                  option: option,
                  selected: mode == option.mode,
                  onTap: () {
                    if (mode == option.mode) return;
                    HapticFeedback.selectionClick();
                    ThemeController.set(option.mode);
                  })),
        ],
      ]),
    );
  }
}

class _Option {
  final ThemeMode mode;
  final String label;
  final IconData icon;
  const _Option(this.mode, this.label, this.icon);
}

const _options = [
  _Option(ThemeMode.system, 'System', Icons.brightness_auto_rounded),
  _Option(ThemeMode.light, 'Light', Icons.light_mode_rounded),
  _Option(ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
];

class _ModeCard extends StatelessWidget {
  final _Option option;
  final bool selected;
  final VoidCallback onTap;
  const _ModeCard(
      {required this.option, required this.selected, required this.onTap});

  static const _lightBg = Color(0xFFF5F7FB);
  static const _lightCard = Colors.white;
  static const _darkBg = Color(0xFF0C1220);
  static const _darkCard = Color(0xFF1A2438);

  Widget _preview() {
    Widget half(Color bg, Color card) => Container(
        color: bg,
        padding: const EdgeInsets.all(7),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              height: 5,
              width: 22,
              decoration: BoxDecoration(
                  color: blue.withValues(alpha: .85),
                  borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 5),
          Expanded(
              child: Container(
                  decoration: BoxDecoration(
                      color: card, borderRadius: BorderRadius.circular(6)))),
        ]));
    final content = switch (option.mode) {
      ThemeMode.light => half(_lightBg, _lightCard),
      ThemeMode.dark => half(_darkBg, _darkCard),
      ThemeMode.system => Row(children: [
          Expanded(child: half(_lightBg, _lightCard)),
          Expanded(child: half(_darkBg, _darkCard)),
        ]),
    };
    return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(height: 58, child: content));
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final label = option.label.tr;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: reduce ? Duration.zero : const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.surfaceTint : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: selected ? blue : AppColors.border,
                  width: selected ? 2 : 1),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: blue.withValues(alpha: .22),
                          blurRadius: 14,
                          offset: const Offset(0, 4))
                    ]
                  : null,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _preview(),
              const SizedBox(height: 9),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(option.icon, size: 15, color: selected ? blue : muted),
                const SizedBox(width: 5),
                Flexible(
                    child: Text(option.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                            color: selected ? blue : muted))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
