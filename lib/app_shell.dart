import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/doc_item.dart';
import 'screens/analysis_page.dart';
import 'screens/assistant_page.dart';
import 'screens/compare_page.dart';
import 'screens/home_page.dart';
import 'screens/insights_page.dart';
import 'screens/library_page.dart';
import 'screens/profile_page.dart';
import 'theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selected = 0;
  String? analysisDocumentPath;
  bool loading = true;
  final List<DocItem> documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('documents');
    if (saved != null) {
      try {
        final parsed = (jsonDecode(saved) as List)
            .map((e) => DocItem.fromJson(e))
            // Drop old demo entries and stale records that have no real local file.
            .where((doc) =>
                doc.path != null &&
                doc.path!.isNotEmpty &&
                File(doc.path!).existsSync())
            .toList();
        documents
          ..clear()
          ..addAll(parsed);
      } catch (_) {}
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _saveDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'documents', jsonEncode(documents.map((e) => e.toJson()).toList()));
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt', 'rtf'],
      withData: true,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.first;
    final ext = (file.extension ?? 'FILE').toUpperCase();
    final size = file.size < 1024 * 1024
        ? '${(file.size / 1024).toStringAsFixed(0)} KB'
        : '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB';
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final storageDir = Directory('${appDir.path}/documents');
      if (!await storageDir.exists()) await storageDir.create(recursive: true);
      final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final storedPath = '${storageDir.path}/${DateTime.now().microsecondsSinceEpoch}_$safeName';
      if (file.bytes != null) {
        await File(storedPath).writeAsBytes(file.bytes!, flush: true);
      } else if (file.path != null) {
        await File(file.path!).copy(storedPath);
      } else {
        throw Exception('The selected file could not be read by the app.');
      }
      setState(() {
        documents.insert(0, DocItem(file.name, ext, size, 'Just now', 'Ready', path: storedPath));
        selected = 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not import this file: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    await _saveDocuments();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${file.name} added to your library'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _openMoreMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
          child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Align(
              alignment: Alignment.centerLeft,
              child: Text('More tools',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: navy))),
          const SizedBox(height: 12),
          ListTile(
              leading: const Icon(Icons.insights_rounded, color: blue),
              title: const Text('Insights'),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => selected = 4);
              }),
          ListTile(
              leading: const Icon(Icons.compare_arrows_rounded, color: blue),
              title: const Text('Compare documents'),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => selected = 5);
              }),
          ListTile(
              leading: const Icon(Icons.person_rounded, color: blue),
              title: const Text('Profile & settings'),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => selected = 6);
              }),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
          docs: documents,
          onUpload: _pickDocument,
          onNavigate: (i) => setState(() => selected = i),
          onOpen: (doc) => setState(() {
            analysisDocumentPath = doc.path;
            selected = 2;
          })),
      LibraryPage(
          docs: documents,
          onUpload: _pickDocument,
          onOpen: (doc) => setState(() {
            analysisDocumentPath = doc.path;
            selected = 2;
          })),
      AnalysisPage(
        docs: documents,
        selectedPath: analysisDocumentPath,
        onSelectPath: (path) => setState(() => analysisDocumentPath = path),
        onUpdate: (updated) async {
        final index = documents.indexWhere((d) => d.name == updated.name && d.path == updated.path);
        if (index >= 0) { documents[index] = updated; await _saveDocuments(); if (mounted) setState(() {}); }
      }),
      AssistantPage(docs: documents),
      InsightsPage(docs: documents),
      ComparePage(docs: documents),
      const ProfilePage(),
    ];
    final labels = [
      'Home',
      'Library',
      'Analyze',
      'AI Assistant',
      'Insights',
      'Compare',
      'Profile'
    ];
    final icons = [
      Icons.grid_view_rounded,
      Icons.folder_copy_rounded,
      Icons.document_scanner_rounded,
      Icons.auto_awesome_rounded,
      Icons.insights_rounded,
      Icons.compare_arrows_rounded,
      Icons.person_rounded
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF477BFF), Color(0xFF2147D8)]),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 20)),
          const SizedBox(width: 10),
          const Text('DocuMind',
              style:
                  TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(width: 5),
          const Text('AI',
              style: TextStyle(color: blue, fontWeight: FontWeight.w800)),
        ]),
        actions: [
          IconButton(
              onPressed: () => setState(() => selected = 3),
              icon: const Icon(Icons.notifications_none_rounded)),
          Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFFE2E9FF),
                  child: const Text('M',
                      style: TextStyle(
                          color: blue, fontWeight: FontWeight.bold)))),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(child: pages[selected]),
      floatingActionButton: selected == 2 || selected == 3 || selected == 6
          ? null
          : FloatingActionButton.extended(
              onPressed: _pickDocument,
              backgroundColor: blue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add document',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected > 4 ? 4 : selected,
        onDestinationSelected: (i) {
          if (i == 4) {
            _openMoreMenu();
          } else {
            setState(() => selected = i);
          }
        },
        height: 70,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE9EFFF),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.grid_view_rounded), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.folder_copy_outlined),
              selectedIcon: Icon(Icons.folder_copy_rounded),
              label: 'Library'),
          NavigationDestination(
              icon: Icon(Icons.document_scanner_outlined),
              selectedIcon: Icon(Icons.document_scanner_rounded),
              label: 'Analyze'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded),
              label: 'Assistant'),
          NavigationDestination(
              icon: Icon(Icons.more_horiz_rounded), label: 'More'),
        ],
      ),
    );
  }
}
