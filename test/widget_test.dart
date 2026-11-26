import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:documind_ai/main.dart';
import 'package:documind_ai/theme/app_theme.dart';
import 'package:documind_ai/theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The appearance choice is global, so every test starts from "System".
  setUp(() => ThemeController.mode.value = ThemeMode.system);

  testWidgets('dark mode repaints the app and keeps the current page',
      (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const DocuMindApp());
    await tester.pumpAndSettle();
    expect(AppPalette.dark, isFalse);

    Color scaffoldColor() => Theme.of(tester.element(find.byType(Scaffold).first))
        .scaffoldBackgroundColor;

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    final light = scaffoldColor();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(AppPalette.dark, isTrue);
    expect(find.text('Appearance'), findsOneWidget, reason: 'still on Profile');
    expect(scaffoldColor(), isNot(light));
    expect(scaffoldColor(), const Color(0xFF0C1220));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(AppPalette.dark, isFalse);
  });

  test('palette tokens switch between the light and dark sets', () {
    addTearDown(() => AppPalette.dark = false);
    AppPalette.dark = false;
    final lightNavy = navy;
    final lightSurface = AppColors.surface;
    AppPalette.dark = true;
    expect(navy, isNot(lightNavy));
    expect(AppColors.surface, isNot(lightSurface));
    // Text must stay readable: dark-mode text is lighter than its surface.
    expect(navy.computeLuminance(), greaterThan(AppColors.surface.computeLuminance()));
    expect(muted.computeLuminance(), greaterThan(AppColors.surface.computeLuminance()));
  });

  testWidgets('DocuMind opens without sample documents', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
    await tester.pumpWidget(const DocuMindApp());
    await tester.pumpAndSettle();

    expect(find.text('DocuMind'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('Add document'), findsOneWidget);
  });

  testWidgets('bottom bar has four destinations and no More tab',
      (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
    await tester.pumpWidget(const DocuMindApp());
    await tester.pumpAndSettle();

    for (final label in ['Home', 'Library', 'Assistant', 'Profile']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('More'), findsNothing);
  });

  testWidgets('home has no overflow on a phone, even with larger text',
      (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final scale in [1.0, 1.3]) {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      await tester.pumpWidget(const DocuMindApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'text scale $scale');
      expect(find.text('Risk review'), findsOneWidget);
    }
  });

  testWidgets('profile shows the free plan and the reminders switch',
      (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
    // Tall screen so the whole paywall is built (it is a lazy list).
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const DocuMindApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Free plan'), findsOneWidget);
    expect(find.text('3 of 3 analyses left this month'), findsOneWidget);
    expect(find.text('Date reminders'), findsOneWidget);

    await tester.tap(find.text('Upgrade'));
    await tester.pumpAndSettle();
    expect(find.text('DocuMind Pro'), findsOneWidget);
    expect(find.textContaining('Preview: purchases are not connected'),
        findsOneWidget);
  });

  testWidgets('Add document offers a file, a camera scan and photos',
      (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
    await tester.pumpWidget(const DocuMindApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add document'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a file'), findsOneWidget);
    expect(find.text('Scan with camera'), findsOneWidget);
    expect(find.text('Import photos'), findsOneWidget);
    expect(find.textContaining('Arabic is not supported'), findsOneWidget);
  });

  testWidgets('first launch shows onboarding once, Skip opens the app',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const DocuMindApp());
    await tester.pumpAndSettle();

    expect(find.text('Understand any document'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Understand any document'), findsNothing);
    expect(find.text('Add document'), findsOneWidget);
  });
}
