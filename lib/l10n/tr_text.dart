import 'package:flutter/material.dart' as m;
import 'l10n.dart';

export 'l10n.dart'
    show L10n, TranslatedString, languageNames, supportedLanguageCodes;

/// A drop-in replacement for Flutter's `Text` that shows the text in the
/// app's current language.
///
/// Every screen writes its texts in English. Here the text is translated
/// when it is drawn, so the same widget works with fixed texts, texts with
/// numbers inside and texts stored earlier (a saved welcome message), and
/// anything without a translation (document names, AI answers) is shown as
/// it is. Import it with:
///   import 'package:flutter/material.dart' hide Text;
///   import '<path>/l10n/tr_text.dart';
class Text extends m.StatelessWidget {
  final String? data;
  final m.InlineSpan? textSpan;
  final m.TextStyle? style;
  final m.StrutStyle? strutStyle;
  final m.TextAlign? textAlign;
  final m.TextDirection? textDirection;
  final bool? softWrap;
  final m.TextOverflow? overflow;
  final m.TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;

  const Text(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
  }) : textSpan = null;

  const Text.rich(
    m.InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
  }) : data = null;

  @override
  m.Widget build(m.BuildContext context) {
    final span = textSpan;
    if (span != null) {
      return m.Text.rich(span,
          style: style,
          strutStyle: strutStyle,
          textAlign: textAlign,
          textDirection: textDirection,
          softWrap: softWrap,
          overflow: overflow,
          textScaler: textScaler,
          maxLines: maxLines,
          semanticsLabel: semanticsLabel);
    }
    return m.Text(L10n.translate(data!),
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel);
  }
}
