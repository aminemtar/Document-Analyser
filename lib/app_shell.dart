import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/doc_item.dart';
import 'services/document_text_extractor.dart';
import 'services/reminder_service.dart';
import 'screens/analysis_page.dart';
import 'screens/assistant_page.dart';
import 'screens/compare_page.dart';
import 'screens/home_page.dart';
import 'screens/insights_page.dart';
import 'screens/library_page.dart';
import 'screens/onboarding_page.dart';
import 'screens/profile_page.dart';
import 'theme/app_theme.dart';

/// Page indexes. The bottom bar only shows four of them; Analyze, Insights
/// and Compare are reached from Home, the Library or a document and show a
/// back button.
abstract final class Pages {
  static const home = 0;
  static const library = 1;
  static const analyze = 2;
  static const assistant = 3;
  static const insights = 4;
  static const compare = 5;
  static const profile = 6;

  /// Page opened by each bottom-bar destination, in bar order.
  static const tabs = [home, library, assistant, profile];

  /// Which bottom-bar destination is highlighted for a page.
  static int tabFor(int page) => switch (page) {
        Pages.library || Pages.analyze => 1,
        Pages.assistant => 2,
        Pages.profile => 3,
        _ => 0,
      };

  static bool isSubPage(int page) =>
      page == analyze || page == insights || page == compare;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selected = Pages.home;
  String? analysisDocumentPath;
  bool analysisAutoRun = false;
  bool loading = true;
  bool showOnboarding = false;
  bool remindersEnabled = false;
  String? pendingQuestion;
  final List<DocItem> documents = [];

  @override
  void initState() {
    super.initState();
    ReminderService.tapped.addListener(_onReminderTapped);
    _loadDocuments();
  }

  @override
  void dispose() {
    ReminderService.tapped.removeListener(_onReminderTapped);
    super.dispose();
  }

  /// Opens the document a tapped reminder is about.
  void _openByPath(String? path) {
    if (path == null || !mounted) return;
    final index = documents.indexWhere((d) => d.path == path);
    if (index >= 0) _openAnalysis(documents[index]);
  }

  void _onReminderTapped() {
    final path = ReminderService.tapped.value;
    if (path == null) return;
    ReminderService.tapped.value = null;
    _openByPath(path);
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
    showOnboarding = !(prefs.getBool('onboarded') ?? false);
    remindersEnabled = prefs.getBool(ReminderService.prefsKey) ?? false;
    if (mounted) setState(() => loading = false);
    await _syncReminders();
    if (remindersEnabled) {
      // The app may have been opened by tapping a reminder while closed.
      try {
        _openByPath(await ReminderService.takeLaunchPayload());
      } catch (_) {}
    }
  }

  Future<void> _renameDocument(DocItem doc, String newName) async {
    final index = documents.indexOf(doc);
    if (index < 0) return;
    setState(() => documents[index] = doc.copyWith(name: newName));
    await _saveDocuments();
  }

  /// Rebuilds the scheduled reminders from the saved analyses. Failures are
  /// ignored on purpose: reminders are a convenience and must never break
  /// saving or opening a document.
  Future<void> _syncReminders() async {
    if (!remindersEnabled) return;
    try {
      await ReminderService.sync(documents);
    } catch (_) {}
  }

  Future<void> _setReminders(bool enabled) async {
    final messenger = ScaffoldMessenger.of(context);
    if (enabled) {
      bool granted = false;
      try {
        granted = await ReminderService.requestPermission();
      } catch (_) {}
      if (!granted) {
        messenger.showSnackBar(const SnackBar(
            content: Text(
                'Notifications are blocked. Allow them for DocuMind in your phone settings to get reminders.'),
            behavior: SnackBarBehavior.floating));
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ReminderService.prefsKey, enabled);
    if (!mounted) return;
    setState(() => remindersEnabled = enabled);
    try {
      if (enabled) {
        await ReminderService.sync(documents);
      } else {
        await ReminderService.cancelAll();
      }
    } catch (_) {}
  }

  Future<void> _finishOnboarding() async {
    setState(() => showOnboarding = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
  }

  Future<void> _saveDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'documents', jsonEncode(documents.map((e) => e.toJson()).toList()));
    _syncReminders();
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
      final storedPath =
          '${storageDir.path}/${DateTime.now().microsecondsSinceEpoch}_$safeName';
      if (file.bytes != null) {
        await File(storedPath).writeAsBytes(file.bytes!, flush: true);
      } else if (file.path != null) {
        await File(file.path!).copy(storedPath);
      } else {
        throw Exception('The selected file could not be read by the app.');
      }
      setState(() {
        documents.insert(
            0, DocItem(file.name, ext, size, 'Just now', 'Ready', path: storedPath));
        analysisAutoRun = false;
        selected = Pages.library;
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

  /// Removes a document right away and offers Undo. The stored file is only
  /// deleted from disk once the snackbar closes without Undo being pressed.
  Future<void> _deleteDocument(DocItem doc) async {
    final index = documents.indexOf(doc);
    if (index < 0) return;
    setState(() {
      documents.removeAt(index);
      if (analysisDocumentPath == doc.path) analysisDocumentPath = null;
    });
    await _saveDocuments();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final controller = messenger.showSnackBar(SnackBar(
      content: Text('${doc.name} deleted'),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          if (!mounted) return;
          setState(() => documents.insert(index.clamp(0, documents.length), doc));
          _saveDocuments();
        },
      ),
    ));
    final reason = await controller.closed;
    if (reason == SnackBarClosedReason.action) return;
    final path = doc.path;
    if (path == null) return;
    DocumentTextExtractor.forget(path);
    try {
      await File(path).delete();
    } catch (_) {
      // The record is already gone; a leftover file is harmless.
    }
  }

  void _openAnalysis(DocItem doc) => setState(() {
        analysisDocumentPath = doc.path;
        analysisAutoRun = true;
        selected = Pages.analyze;
      });

  void _goTo(int page) => setState(() {
        analysisAutoRun = false;
        selected = page;
      });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (showOnboarding) return OnboardingPage(onDone: _finishOnboarding);
    final pages = <int, Widget>{
      Pages.home: HomePage(
          docs: documents,
          onUpload: _pickDocument,
          onNavigate: _goTo,
          onOpen: _openAnalysis),
      Pages.library: LibraryPage(
          docs: documents,
          onUpload: _pickDocument,
          onOpen: _openAnalysis,
          onDelete: _deleteDocument,
          onRename: _renameDocument),
      Pages.analyze: AnalysisPage(
          docs: documents,
          selectedPath: analysisDocumentPath,
          autoRun: analysisAutoRun,
          onAsk: (question) => setState(() {
                pendingQuestion = question;
                analysisAutoRun = false;
                selected = Pages.assistant;
              }),
          onSelectPath: (path) => setState(() => analysisDocumentPath = path),
          onUpdate: (updated) async {
            // Match on the stored path: the name can change (rename) while
            // an analysis is still running.
            final index = documents.indexWhere((d) => d.path == updated.path);
            if (index >= 0) {
              documents[index] = updated;
              await _saveDocuments();
              if (mounted) setState(() {});
            }
          }),
      Pages.assistant: AssistantPage(
          docs: documents,
          pendingQuestion: pendingQuestion,
          onPendingConsumed: () {
            if (mounted) setState(() => pendingQuestion = null);
          }),
      Pages.insights: InsightsPage(docs: documents),
      Pages.compare: ComparePage(docs: documents),
      Pages.profile: ProfilePage(
          remindersEnabled: remindersEnabled,
          onRemindersChanged: _setReminders),
    };
    final isSubPage = Pages.isSubPage(selected);
    return PopScope(
      // Back from a sub-page or another tab returns Home instead of closing.
      canPop: selected == Pages.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _goTo(selected == Pages.analyze ? Pages.library : Pages.home);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: isSubPage
              ? IconButton(
                  tooltip: 'Back',
                  onPressed: () =>
                      _goTo(selected == Pages.analyze ? Pages.library : Pages.home),
                  icon: const Icon(Icons.arrow_back_rounded))
              : null,
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
            // One flexible text, so a small screen or a large text setting
            // shortens the title instead of overflowing the app bar.
            Flexible(
                child: Text.rich(
                    TextSpan(
                        style: TextStyle(
                            fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        children: [
                          TextSpan(text: 'DocuMind '),
                          TextSpan(text: 'AI', style: TextStyle(color: blue)),
                        ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ]),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(child: pages[selected]!),
        floatingActionButton: selected == Pages.analyze ||
                selected == Pages.assistant ||
                selected == Pages.profile
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
          selectedIndex: Pages.tabFor(selected),
          onDestinationSelected: (i) => _goTo(Pages.tabs[i]),
          height: 70,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.surfaceTint,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.folder_copy_outlined),
                selectedIcon: Icon(Icons.folder_copy_rounded),
                label: 'Library'),
            NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome_rounded),
                label: 'Assistant'),
            NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
