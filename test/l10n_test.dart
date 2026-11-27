import 'package:documind_ai/l10n/l10n.dart';
import 'package:documind_ai/l10n/translations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => L10n.language.value = 'en');

  test('English text is never changed', () {
    expect(L10n.translate('Add document'), 'Add document');
    expect(L10n.translate('whatever 42'), 'whatever 42');
  });

  test('translates fixed texts to French and Arabic', () {
    expect(L10n.translate('Library', to: 'fr'), 'Bibliothèque');
    expect(L10n.translate('Library', to: 'ar'), 'المكتبة');
  });

  test('uses the current language by default', () {
    L10n.language.value = 'fr';
    expect('Home'.tr, 'Accueil');
    expect(L10n.isRtl, isFalse);
    L10n.language.value = 'ar';
    expect('Home'.tr, 'الرئيسية');
    expect(L10n.isRtl, isTrue);
  });

  test('texts without a translation pass through (names, AI answers)', () {
    expect(L10n.translate('contract_final.pdf', to: 'fr'), 'contract_final.pdf');
    expect(L10n.translate('Some sentence the AI wrote.', to: 'ar'),
        'Some sentence the AI wrote.');
  });

  test('translates texts with numbers and names inside', () {
    expect(L10n.translate('12 files in your workspace', to: 'fr'),
        '12 fichiers dans votre espace');
    expect(L10n.translate('In 3 days', to: 'ar'), 'بعد 3 أيام');
    expect(L10n.translate('lease.pdf deleted', to: 'fr'), 'lease.pdf supprimé');
    expect(L10n.translate('512 KB', to: 'fr'), '512 Ko');
    expect(L10n.translate('Good morning 👋', to: 'fr'), 'Bonjour 👋');
  });

  test('translates each part of a dotted line', () {
    expect(L10n.translate('Tomorrow · lease.pdf', to: 'fr'),
        'Demain · lease.pdf');
    expect(L10n.translate('1 MB · PDF · Analyzed', to: 'fr'),
        '1 Mo · PDF · Analysé');
  });

  test('picks the language from the choice and the phone', () {
    expect(L10n.resolve('fr', 'en'), 'fr');
    expect(L10n.resolve('system', 'ar'), 'ar');
    expect(L10n.resolve('system', 'de'), 'en');
  });

  test('French and Arabic cover the same texts', () {
    expect(frTexts.keys.toSet(), arTexts.keys.toSet());
    for (final entry in {...frTexts, ...arTexts}.entries) {
      expect(entry.value.trim(), isNotEmpty);
    }
  });
}
