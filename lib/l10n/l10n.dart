import 'package:flutter/foundation.dart';
import 'translations.dart';

/// App languages. English is the source language of every text in the app;
/// French and Arabic are looked up by the English text (see translations.dart).
const supportedLanguageCodes = ['en', 'fr', 'ar'];

/// Name of each language in that language, so a user can always find theirs.
const languageNames = {'en': 'English', 'fr': 'Français', 'ar': 'العربية'};

abstract final class L10n {
  /// The language currently shown: 'en', 'fr' or 'ar'.
  static final ValueNotifier<String> language = ValueNotifier('en');

  static bool get isRtl => language.value == 'ar';

  /// The language the AI should write its answers in.
  static String get aiLanguageName => switch (language.value) {
        'fr' => 'French',
        'ar' => 'Arabic',
        _ => 'English',
      };

  /// The language to use for a saved choice ('system', 'en', 'fr', 'ar')
  /// given the phone's language code. Unsupported phone languages use English.
  static String resolve(String choice, String deviceLanguageCode) {
    if (supportedLanguageCodes.contains(choice)) return choice;
    return supportedLanguageCodes.contains(deviceLanguageCode)
        ? deviceLanguageCode
        : 'en';
  }

  /// Translates [text] (written in English) into the current language.
  /// Returns it unchanged when English is shown or no translation exists, so
  /// document names, AI answers and anything else pass through untouched.
  static final Map<String, Map<String, String>> _cache = {'fr': {}, 'ar': {}};

  static String translate(String text, {String? to}) {
    final lang = to ?? language.value;
    if (lang == 'en' || text.isEmpty) return text;
    // Texts are drawn again and again (every rebuild, every scroll frame), so
    // the result of the pattern search is remembered. Document names and AI
    // answers are one-off, so the cache is emptied if it grows large.
    final cache = _cache[lang]!;
    final hit = cache[text];
    if (hit != null) return hit;
    final result = _translate(text, lang);
    if (cache.length > 2000) cache.clear();
    return cache[text] = result;
  }

  static String _translate(String text, String lang) {
    final table = lang == 'fr' ? frTexts : arTexts;
    final direct = table[text];
    if (direct != null) return direct;

    for (final (pattern, fr, ar) in textPatterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      final template = lang == 'fr' ? fr : ar;
      return template.replaceAllMapped(RegExp(r'\$(\d)'), (m) {
        final group = match.group(int.parse(m.group(1)!)) ?? '';
        return translate(group, to: lang);
      });
    }

    // "Today · lease.pdf": translate each part of a dotted line.
    if (text.contains(' · ')) {
      return text
          .split(' · ')
          .map((part) => translate(part, to: lang))
          .join(' · ');
    }
    return text;
  }
}

extension TranslatedString on String {
  /// This English text in the current language.
  String get tr => L10n.translate(this);
}
