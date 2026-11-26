import 'dart:convert';
import 'doc_item.dart';

enum AttentionKind { highRisk, upcomingDate }

/// One thing in the library that deserves a look soon.
class AttentionItem {
  final AttentionKind kind;
  final String title;
  final DocItem doc;

  /// Set for [AttentionKind.upcomingDate]: the calendar day, without a time.
  final DateTime? when;
  const AttentionItem(
      {required this.kind, required this.title, required this.doc, this.when});
}

/// Collects what deserves a look from the saved analyses: high-level risks,
/// and dates that fall between today and [windowDays] days from [now].
///
/// Everything is read from analyses already stored on the device, so this
/// needs no network. Dated items come first, soonest first.
List<AttentionItem> collectAttention(List<DocItem> docs, DateTime now,
    {int windowDays = 30}) {
  final today = DateTime(now.year, now.month, now.day);
  final limit = today.add(Duration(days: windowDays));
  final items = <AttentionItem>[];
  for (final doc in docs) {
    final raw = doc.analysisJson;
    if (raw == null) continue;
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      continue;
    }
    final risks = data['risks'];
    if (risks is List) {
      for (final risk in risks) {
        if (risk is Map &&
            (risk['level'] ?? '').toString().toLowerCase().contains('high')) {
          items.add(AttentionItem(
              kind: AttentionKind.highRisk,
              title: (risk['title'] ?? 'High risk').toString(),
              doc: doc));
        }
      }
    }
    final dates = data['important_dates'];
    if (dates is List) {
      for (final entry in dates) {
        if (entry is! Map) continue;
        final parsed = DateTime.tryParse((entry['date'] ?? '').toString());
        if (parsed == null) continue;
        final day = DateTime(parsed.year, parsed.month, parsed.day);
        if (day.isBefore(today) || day.isAfter(limit)) continue;
        items.add(AttentionItem(
            kind: AttentionKind.upcomingDate,
            title: (entry['label'] ?? 'Upcoming date').toString(),
            doc: doc,
            when: day));
      }
    }
  }
  items.sort((a, b) {
    if (a.when != null && b.when != null) return a.when!.compareTo(b.when!);
    if (a.when != null) return -1;
    if (b.when != null) return 1;
    return 0;
  });
  return items;
}
