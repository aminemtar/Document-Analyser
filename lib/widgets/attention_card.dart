import 'package:flutter/material.dart' hide Text;
import '../l10n/tr_text.dart';
import '../models/attention.dart';
import '../models/doc_item.dart';
import '../theme/app_theme.dart';

/// Home card listing upcoming dates and high risks found in analyzed
/// documents. Renders nothing when there is nothing to flag.
class AttentionCard extends StatelessWidget {
  final List<DocItem> docs;
  final ValueChanged<DocItem> onOpen;
  const AttentionCard({super.key, required this.docs, required this.onOpen});

  String _when(DateTime day, DateTime today) {
    final days = day.difference(today).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return 'In $days days';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final items = collectAttention(docs, now);
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.notifications_active_outlined, color: blue, size: 20),
          SizedBox(width: 8),
          Text('Needs attention',
              style: TextStyle(
                  color: navy, fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 10),
        ...items.take(4).map((item) {
          final dated = item.when != null;
          final color = dated ? blue : AppColors.danger;
          return InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: () => onOpen(item.doc),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(
                        dated
                            ? Icons.event_rounded
                            : Icons.warning_amber_rounded,
                        color: color,
                        size: 19)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: navy,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      Text(
                          dated
                              ? '${_when(item.when!, today)} · ${item.doc.name}'
                              : 'High risk · ${item.doc.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: muted, fontSize: 12)),
                    ])),
                Icon(Icons.chevron_right_rounded, color: muted),
              ]),
            ),
          );
        }),
        if (items.length > 4)
          Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('+${items.length - 4} more in your analyses',
                  style: TextStyle(color: muted, fontSize: 12))),
      ]),
    );
  }
}
