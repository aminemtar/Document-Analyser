import 'dart:math' as math;
import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import '../l10n/tr_text.dart';
import '../theme/app_theme.dart';

/// One tab of a [PremiumTabBar].
class PremiumTab {
  final IconData icon;

  /// English label; translated when shown.
  final String label;

  /// Small count shown on the icon while the tab is not selected.
  final int? badge;
  final Color? badgeColor;
  const PremiumTab(this.icon, this.label, {this.badge, this.badgeColor});
}

/// A segmented switcher where the selected tab grows into a glowing
/// gradient pill with its name, and the others shrink to icons.
/// It saves space (five tabs fit a phone) and reads as navigation inside a
/// result, not as a row of filter chips.
class PremiumTabBar extends StatelessWidget {
  final List<PremiumTab> tabs;
  final int selected;
  final ValueChanged<int> onChanged;
  const PremiumTabBar(
      {super.key,
      required this.tabs,
      required this.selected,
      required this.onChanged});

  static const _height = 48.0;
  static const _padding = 4.0;
  static const _minOther = 44.0;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 240);
    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
          color: pale,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border)),
      child: LayoutBuilder(builder: (context, constraints) {
        final n = tabs.length;
        final inner = constraints.maxWidth - _padding * 2;
        final selectedWidth = math.min(
            math.max(inner * 0.36, 96.0), inner - (n - 1) * _minOther);
        final otherWidth = (inner - selectedWidth) / (n - 1);
        final showLabel = selectedWidth >= 84;
        return Row(children: [
          for (var i = 0; i < n; i++)
            _segment(context, i, i == selected ? selectedWidth : otherWidth,
                i == selected, showLabel, duration),
        ]);
      }),
    );
  }

  Widget _segment(BuildContext context, int index, double width, bool isSelected,
      bool showLabel, Duration duration) {
    final tab = tabs[index];
    final badge = tab.badge;
    final content = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      width: width,
      height: _height,
      decoration: BoxDecoration(
        gradient: isSelected ? LinearGradient(colors: AppColors.heroGradient) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected
            ? [
                BoxShadow(
                    color: blue.withValues(alpha: .38),
                    blurRadius: 14,
                    offset: const Offset(0, 5))
              ]
            : const [],
      ),
      child: Stack(alignment: Alignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(tab.icon, size: 20, color: isSelected ? Colors.white : muted),
          if (isSelected && showLabel) ...[
            const SizedBox(width: 6),
            Flexible(
                child: Text(tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800))),
          ],
        ]),
        if (!isSelected && badge != null && badge > 0)
          PositionedDirectional(
              top: 4,
              end: 5,
              child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: tab.badgeColor ?? blue,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('$badge',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)))),
      ]),
    );
    final button = Semantics(
      button: true,
      selected: isSelected,
      label: tab.label.tr,
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isSelected
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onChanged(index);
                },
          child: content,
        ),
      ),
    );
    // Icon-only tabs still say what they are on long press.
    return isSelected ? button : Tooltip(message: tab.label.tr, child: button);
  }
}
