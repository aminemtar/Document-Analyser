import 'package:documind_ai/models/doc_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const doc = DocItem('lease.pdf', 'PDF', '1 KB', 'Just now', 'Analyzed',
      path: '/stored/1_lease.pdf', analysisJson: '{"summary":"x"}');

  test('copyWith(name) renames without touching the file or the analysis', () {
    final renamed = doc.copyWith(name: 'Apartment lease');
    expect(renamed.name, 'Apartment lease');
    expect(renamed.path, doc.path);
    expect(renamed.analysisJson, doc.analysisJson);
    expect(renamed.type, 'PDF');
  });

  test('copyWith with no arguments keeps everything', () {
    final copy = doc.copyWith();
    expect(copy.name, doc.name);
    expect(copy.status, doc.status);
  });

  test('a renamed document survives a save and load round trip', () {
    final renamed = doc.copyWith(name: 'Renamed');
    final loaded = DocItem.fromJson(renamed.toJson());
    expect(loaded.name, 'Renamed');
    expect(loaded.path, doc.path);
  });
}
