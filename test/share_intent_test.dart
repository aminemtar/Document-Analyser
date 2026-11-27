import 'package:documind_ai/services/share_intent_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes the document types the app can read', () {
    expect(documentTypeFor('Lease.PDF'), 'PDF');
    expect(documentTypeFor('contract.docx'), 'DOCX');
    expect(documentTypeFor('notes.txt'), 'TXT');
    expect(documentTypeFor('a.b.rtf'), 'RTF');
    expect(documentTypeFor('old.doc'), isNull);
    expect(documentTypeFor('noextension'), isNull);
  });

  test('recognizes photos', () {
    expect(isImageName('IMG_1.JPG'), isTrue);
    expect(isImageName('scan.png'), isTrue);
    expect(isImageName('scan.pdf'), isFalse);
    expect(isImageName('scan'), isFalse);
  });

  test('formats file sizes', () {
    expect(formatFileSize(512 * 1024), '512 KB');
    expect(formatFileSize((1.5 * 1024 * 1024).round()), '1.5 MB');
  });

  test('reads the list sent by the Android side and skips bad entries', () {
    final files = parseSharedFiles([
      {'path': '/cache/a.pdf', 'name': 'a.pdf'},
      {'path': 1, 'name': 'bad'},
      'junk',
    ]);
    expect(files, hasLength(1));
    expect(files.single.name, 'a.pdf');
    expect(parseSharedFiles(null), isEmpty);
  });

  test('with no Android side (tests, iOS) nothing arrives', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await ShareIntentService.takeInitial(), isEmpty);
  });
}
