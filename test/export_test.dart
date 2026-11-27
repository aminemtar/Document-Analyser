import 'dart:convert';
import 'package:documind_ai/models/doc_item.dart';
import 'package:documind_ai/screens/library_page.dart';
import 'package:documind_ai/services/export_service.dart';
import 'package:documind_ai/services/openrouter_document_ai.dart';
import 'package:documind_ai/services/reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final analysis = {
    'summary': 'A rental agreement for one year.',
    'key_details': ['Landlord: Sami', 'Rent: 900 TND'],
    'risks': [
      {'level': 'high', 'title': 'Early exit fee', 'detail': 'Two months of rent'}
    ],
    'important_dates': [
      {'label': 'Lease ends', 'date': '2027-06-30', 'note': 'Give notice before'}
    ],
    'amounts': [
      {'label': 'Deposit', 'value': '1800 TND'}
    ],
    'action_items': ['Sign both copies'],
  };

  DocItem doc({String name = 'lease.pdf', Object? data}) => DocItem(
      name, 'PDF', '1 MB', 'Today', 'Analyzed',
      path: '/device/only/lease.pdf',
      analysisJson: data == null ? null : jsonEncode(data));

  test('analysis text includes every section', () {
    final text = analysisToText('lease.pdf', analysis);
    expect(text, contains('A rental agreement'));
    expect(text, contains('- Rent: 900 TND'));
    expect(text, contains('- Early exit fee: Two months of rent'));
    expect(text, contains('- Lease ends: 2027-06-30 - Give notice before'));
    expect(text, contains('- Deposit: 1800 TND'));
    expect(text, contains('- Sign both copies'));
  });

  test('analysis text copes with an almost empty analysis', () {
    final text = analysisToText('x.txt', {'summary': 'Short.'});
    expect(text, contains('Short.'));
    expect(text, isNot(contains('Risks')));
  });

  group('backup', () {
    test('round trips analyses and drops device paths', () {
      final restored =
          parseBackup(buildBackup([doc(data: analysis)], now: DateTime(2026)));
      expect(restored, hasLength(1));
      expect(restored.single.name, 'lease.pdf');
      expect(restored.single.path, isNull);
      expect(jsonDecode(restored.single.analysisJson!)['summary'],
          analysis['summary']);
    });

    test('rejects files that are not backups', () {
      expect(() => parseBackup('not json'), throwsFormatException);
      expect(() => parseBackup('{"format":"other"}'), throwsFormatException);
    });

    test('rejects a backup from a newer app version', () {
      expect(
          () => parseBackup(
              '{"format":"documind-backup","version":99,"documents":[]}'),
          throwsFormatException);
    });

    test('restoring twice does not duplicate documents', () {
      final existing = [doc(data: analysis)];
      final restored = parseBackup(buildBackup(existing));
      expect(mergeRestored(existing, restored), isEmpty);
      expect(mergeRestored(const [], restored), hasLength(1));
    });
  });

  group('library search', () {
    test('finds by name and by what the analysis says', () {
      final d = doc(data: analysis);
      expect(matchesQuery(d, ''), isTrue);
      expect(matchesQuery(d, 'LEASE'), isTrue);
      expect(matchesQuery(d, 'exit fee'), isTrue);
      expect(matchesQuery(d, '1800'), isTrue);
      expect(matchesQuery(d, 'passport'), isFalse);
    });

    test('does not match JSON key names', () {
      expect(matchesQuery(doc(data: analysis), 'key_details'), isFalse);
    });

    test('a document without analysis matches by name only', () {
      expect(matchesQuery(doc(), 'lease'), isTrue);
      expect(matchesQuery(doc(), 'rent'), isFalse);
    });
  });

  group('streamed answers', () {
    test('reads the text of a data line', () {
      expect(
          parseSseDelta('data: {"choices":[{"delta":{"content":"Hel"}}]}'),
          'Hel');
    });

    test('ignores comments, blanks, DONE and bad lines', () {
      expect(parseSseDelta(': OPENROUTER PROCESSING'), isNull);
      expect(parseSseDelta(''), isNull);
      expect(parseSseDelta('data: [DONE]'), isNull);
      expect(parseSseDelta('data: {oops'), isNull);
      expect(parseSseDelta('data: {"choices":[{"delta":{}}]}'), isNull);
    });
  });

  group('weekly digest', () {
    test('is the coming Monday at 09:00', () {
      // Friday 27 Nov 2026 -> Monday 30 Nov.
      expect(nextWeeklyDigest(DateTime(2026, 11, 27, 22)),
          DateTime(2026, 11, 30, 9));
    });

    test('on Monday before 09:00 it is the same day', () {
      expect(nextWeeklyDigest(DateTime(2026, 11, 30, 8)),
          DateTime(2026, 11, 30, 9));
    });

    test('on Monday after 09:00 it is next week', () {
      expect(nextWeeklyDigest(DateTime(2026, 11, 30, 9, 1)),
          DateTime(2026, 12, 7, 9));
    });
  });
}
