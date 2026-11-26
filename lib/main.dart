import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_shell.dart';
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
  runApp(const DocuMindApp());
}

class DocuMindApp extends StatefulWidget {
  const DocuMindApp({super.key});
  @override
  State<DocuMindApp> createState() => _DocuMindAppState();
}

class _DocuMindAppState extends State<DocuMindApp>
    with WidgetsBindingObserver {
  late bool _dark;

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
    WidgetsBinding.instance.addObserver(this);
    ThemeController.mode.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeController.mode.removeListener(_onThemeChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => _onThemeChanged();

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
        home: const AppShell(),
      );
}
