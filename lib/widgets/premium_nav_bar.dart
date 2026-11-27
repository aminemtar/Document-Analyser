import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import '../l10n/tr_text.dart';
import '../theme/app_theme.dart';

/// One tab of [PremiumNavBar].
class NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label; // English; translated when drawn.
  const NavItem(this.icon, this.selectedIcon, this.label);
}

/// A floating, rounded bottom bar. The selected tab gets a gradient pill that
/// slides in, and its icon and label turn bold; the others stay quiet.
class PremiumNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NavItem> items;
  const PremiumNavBar(
      {super.key,
      required this.selectedIndex,
      required this.onSelected,
      required this.items});

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 280);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: AppPalette.dark ? .45 : .10),
                blurRadius: 16,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Row(children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _Tab(
                item: items[i],
                selected: i == selectedIndex,
                duration: duration,
                onTap: () {
                  if (i != selectedIndex) HapticFeedback.selectionClick();
                  onSelected(i);
                },
              ),
            ),
        ]),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;
  const _Tab(
      {required this.item,
      required this.selected,
      required this.duration,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = item.label.tr;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: selected
                  ? LinearGradient(colors: [
                      blue.withValues(alpha: .20),
                      blue.withValues(alpha: .08),
                    ], begin: Alignment.topCenter, end: Alignment.bottomCenter)
                  : null,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedScale(
                scale: selected ? 1.12 : 1,
                duration: duration,
                curve: Curves.easeOutBack,
                child: Icon(selected ? item.selectedIcon : item.icon,
                    size: 24, color: selected ? blue : muted),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: duration,
                style: TextStyle(
                    fontSize: 11,
                    // One weight for every state: animating the weight
                    // would re-measure the text on each frame.
                    fontWeight: FontWeight.w700,
                    color: selected ? blue : muted),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: duration,
                width: selected ? 18 : 0,
                height: 3,
                decoration: BoxDecoration(
                    color: blue, borderRadius: BorderRadius.circular(2)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
