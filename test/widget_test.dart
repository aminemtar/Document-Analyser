import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:documind_ai/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DocuMind opens without sample documents', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const DocuMindApp());
    await tester.pumpAndSettle();

    expect(find.text('DocuMind'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('Add a document'), findsOneWidget);
  });
}
