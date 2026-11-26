import 'dart:convert';
import 'package:documind_ai/models/attention.dart';
import 'package:documind_ai/models/doc_item.dart';
import 'package:flutter_test/flutter_test.dart';

DocItem docWith(Object? analysis, {String name = 'lease.pdf'}) => DocItem(
      name,
      'PDF',
      '1 KB',
      'Just now',
      'Analyzed',
      path: '/tmp/$name',
      analysisJson: analysis is String ? analysis : jsonEncode(analysis),
    );

void main() {
  final now = DateTime(2026, 11, 26, 9);

  test('documents without an analysis add nothing', () {
    final doc = DocItem('a.pdf', 'PDF', '1 KB', 'Just now', 'Ready',
        path: '/tmp/a.pdf');
    expect(collectAttention([doc], now), isEmpty);
  });

  test('keeps dates inside the window, soonest first', () {
    final doc = docWith({
      'important_dates': [
        {'label': 'Renewal', 'date': '2026-12-03'},
        {'label': 'Payment due', 'date': '2026-11-26'},
        {'label': 'Old', 'date': '2026-11-01'},
        {'label': 'Far away', 'date': '2027-03-01'},
        {'label': 'No date', 'date': null},
      ],
    });
    final items = collectAttention([doc], now);
    expect(items.map((i) => i.title), ['Payment due', 'Renewal']);
    expect(items.every((i) => i.kind == AttentionKind.upcomingDate), isTrue);
  });

  test('high risks follow dated items; other levels are ignored', () {
    final doc = docWith({
      'risks': [
        {'level': 'High', 'title': 'Auto-renewal'},
        {'level': 'Low', 'title': 'Minor wording'},
      ],
      'important_dates': [
        {'label': 'Notice deadline', 'date': '2026-12-10'},
      ],
    });
    final items = collectAttention([doc], now);
    expect(items.map((i) => i.title), ['Notice deadline', 'Auto-renewal']);
    expect(items.last.kind, AttentionKind.highRisk);
  });

  test('malformed analysis JSON is skipped', () {
    expect(collectAttention([docWith('not json')], now), isEmpty);
  });
}
