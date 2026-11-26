import 'dart:io';

import 'package:documind_ai/services/document_text_extractor.dart';
import 'package:documind_ai/services/scan_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('joinScanPages', () {
    test('a single page is returned as is, trimmed', () {
      expect(joinScanPages(['  Hello world  ']), 'Hello world');
    });

    test('several pages are labelled and empty pages are dropped', () {
      final text = joinScanPages(['First page', '   ', 'Second page']);
      expect(text, '--- Page 1 ---\nFirst page\n\n--- Page 2 ---\nSecond page');
    });

    test('nothing recognized gives an empty string', () {
      expect(joinScanPages(['', '  ']), isEmpty);
      expect(joinScanPages([]), isEmpty);
    });
  });

  test('scanName is readable and zero-padded', () {
    expect(scanName(DateTime(2026, 3, 4, 9, 5)), 'Scan 2026-03-04 09:05');
  });

  test('a scan shorter than the minimum is not worth keeping', () {
    expect(joinScanPages(['Hi']).length, lessThan(minScanTextLength));
  });

  test('a SCAN document is read as text and flagged as OCR output', () async {
    final dir = await Directory.systemTemp.createTemp('scan_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/1_scan.txt')
      ..writeAsStringSync('Invoice total 120 EUR due 2026-12-01');

    final text = await DocumentTextExtractor.extract(file.path, 'SCAN');

    expect(text, contains('may contain recognition errors'));
    expect(text, contains('Invoice total 120 EUR due 2026-12-01'));
  });
}
