import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_shell.dart';
import 'l10n/l10n.dart';
import 'l10n/locale_controller.dart';
import 'services/ad_service.dart';
import 'services/billing_service.dart';
import 'services/usage_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Keep the app usable; the analysis screen explains how to configure the key.
  }
  await ThemeController.load();
  await LocaleController.load();
  await UsageService.isPro();
  runApp(const DocuMindApp());
  // Store and ads start after the first frame so they never delay launch.
  unawaited(BillingService.init());
  unawaited(AdService.init());
}

class DocuMindApp extends StatefulWidget {
  const DocuMindApp({super.key});
  @override
  State<DocuMindApp> createState() => _DocuMindAppState();
}

class _DocuMindAppState extends State<DocuMindApp>
    with WidgetsBindingObserver {
  late bool _dark;

  String _resolveLanguage() => L10n.resolve(LocaleController.choice.value,
      WidgetsBinding.instance.platformDispatcher.locale.languageCode);

  bool _resolveDark() => switch (ThemeController.mode.value) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system =>
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark,
      };

  @override
  void initState() {
    super.initState();
    _dark = _resolveDark();
    AppPalette.dark = _dark;
    L10n.language.value = _resolveLanguage();
    WidgetsBinding.instance.addObserver(this);
    ThemeController.mode.addListener(_onThemeChanged);
    LocaleController.choice.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    ThemeController.mode.removeListener(_onThemeChanged);
    LocaleController.choice.removeListener(_onLanguageChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => _onThemeChanged();

  @override
  void didChangeLocales(List<Locale>? locales) => _onLanguageChanged();

  /// Every text is translated when it is drawn, so a language change only
  /// needs the whole tree to be drawn again (const widgets included).
  void _onLanguageChanged() {
    final language = _resolveLanguage();
    if (language == L10n.language.value) return;
    L10n.language.value = language;
    setState(() {});
    _rebuildEverything();
  }

  void _onThemeChanged() {
    final dark = _resolveDark();
    if (dark == _dark) return;
    _dark = dark;
    AppPalette.dark = dark;
    setState(() {});
    _rebuildEverything();
  }

  /// Colors are read while building, but `const` widgets are skipped when
  /// their parent rebuilds. Marking every element dirty makes them all pick
  /// up the new palette in the next frame, without losing any state.
  void _rebuildEverything() {
    void visit(Element element) {
      element.markNeedsBuild();
      element.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'DocuMind AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        locale: Locale(L10n.language.value),
        supportedLocales: [for (final c in supportedLanguageCodes) Locale(c)],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AppShell(),
      );
}
