import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_shell.dart';
import 'l10n/l10n.dart';
import 'l10n/locale_controller.dart';
import 'services/ad_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _lockPortraitOnPhones();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Keep the app usable; the analysis screen explains how to configure the key.
  }
  await ThemeController.load();
  await LocaleController.load();
  runApp(const DocuMindApp());
  // Ads start after the first frame so they never delay launch.
  unawaited(AdService.init());
}

class DocuMindApp extends StatefulWidget {
  const DocuMindApp({super.key});
  @override
  State<DocuMindApp> createState() => _DocuMindAppState();
}

class _DocuMindAppState extends State<DocuMindApp>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late bool _dark;
  final GlobalKey _appKey = GlobalKey();
  late final AnimationController _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
      value: 0)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        final image = _snapshot;
        setState(() => _snapshot = null);
        WidgetsBinding.instance
            .addPostFrameCallback((_) => image?.dispose());
      }
    });
  ui.Image? _snapshot;
  bool _toDark = true;
  Offset? _origin;

  /// Picture of the screen before the theme changes. It is faded out over the
  /// new theme, so the switch is a smooth cross-fade instead of a hard cut.
  void _captureOldFrame() {
    try {
      final boundary =
          _appKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || !boundary.hasSize) return;
      _snapshot?.dispose();
      _snapshot = boundary.toImageSync(
          pixelRatio: WidgetsBinding
              .instance.platformDispatcher.views.first.devicePixelRatio);
    } catch (_) {
      _snapshot = null; // No smooth fade available: the theme just switches.
    }
  }

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
    _fade.dispose();
    _snapshot?.dispose();
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
    _captureOldFrame();
    _toDark = dark;
    _origin = ThemeController.revealOrigin;
    ThemeController.revealOrigin = null;
    _dark = dark;
    AppPalette.dark = dark;
    setState(() {});
    _rebuildEverything();
    if (_snapshot != null) _fade.forward(from: 0);
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
  Widget build(BuildContext context) {
    final app = MaterialApp(
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
    final old = _snapshot;
    return Stack(textDirection: TextDirection.ltr, children: [
      Positioned.fill(key: const ValueKey('app'), child: RepaintBoundary(key: _appKey, child: app)),
      if (old != null)
        Positioned.fill(
            child: IgnorePointer(
                child: AnimatedBuilder(
                    animation: _fade,
                    builder: (context, _) => CustomPaint(
                        painter: _RevealPainter(
                            image: old,
                            progress: Curves.easeInOutCubic.transform(_fade.value),
                            toDark: _toDark,
                            origin: _origin))))),
    ]);
  }
}


/// Phones stay in portrait; tablets (shortest side >= 600dp) may rotate.
Future<void> _lockPortraitOnPhones() async {
  final views = WidgetsBinding.instance.platformDispatcher.views;
  if (views.isEmpty) return;
  final view = views.first;
  final shortest = view.physicalSize.shortestSide / view.devicePixelRatio;
  if (shortest < 600) {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }
}


/// Draws the screen as it was before the theme change, with a circle cut out
/// of it. Going to dark, the new theme grows out of the switch until it covers
/// the whole screen. Going back to light, the dark area shrinks back into the
/// switch until it disappears.
class _RevealPainter extends CustomPainter {
  final ui.Image image;
  final double progress; // 0..1
  final bool toDark;
  final Offset? origin;
  _RevealPainter(
      {required this.image,
      required this.progress,
      required this.toDark,
      required this.origin});

  @override
  void paint(Canvas canvas, Size size) {
    final center = origin ?? Offset(size.width - 40, 28);
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    final maxRadius =
        corners.map((c) => (c - center).distance).reduce((a, b) => a > b ? a : b);
    final bounds = Offset.zero & size;
    final path = Path();
    if (toDark) {
      // Old (light) screen everywhere except the growing circle.
      path
        ..fillType = PathFillType.evenOdd
        ..addRect(bounds)
        ..addOval(Rect.fromCircle(center: center, radius: maxRadius * progress));
    } else {
      // Old (dark) screen only inside a circle that shrinks into the switch.
      path.addOval(
          Rect.fromCircle(center: center, radius: maxRadius * (1 - progress)));
    }
    canvas.save();
    canvas.clipPath(path);
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        bounds,
        Paint()..filterQuality = FilterQuality.low);
    canvas.restore();
    // A thin light edge on the moving circle.
    final radius = maxRadius * (toDark ? progress : 1 - progress);
    if (progress > 0 && progress < 1 && radius > 1) {
      canvas.drawCircle(
          center,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = (toDark ? const Color(0xFF5B8CFF) : const Color(0xFFFFC857))
                .withValues(alpha: .55 * (1 - (progress - .5).abs() * 2)));
    }
  }

  @override
  bool shouldRepaint(covariant _RevealPainter old) =>
      old.progress != progress ||
      old.image != image ||
      old.toDark != toDark ||
      old.origin != origin;
}
