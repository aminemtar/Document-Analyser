import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:documind_ai/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('profile shows the free plan and the reminders switch',
      (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
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
