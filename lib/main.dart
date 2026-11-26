import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Keep the app usable; the analysis screen explains how to configure the key.
  }
  runApp(const DocuMindApp());
}

class DocuMindApp extends StatelessWidget {
  const DocuMindApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'DocuMind AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppShell(),
      );
}
