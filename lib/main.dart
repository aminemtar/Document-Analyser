import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:xml/xml.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

const navy = Color(0xFF101B3D);
const blue = Color(0xFF3568F5);
const pale = Color(0xFFF3F6FC);
const muted = Color(0xFF8792A8);

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
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(seedColor: blue, brightness: Brightness.light),
      scaffoldBackgroundColor: pale,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
          backgroundColor: pale,
          foregroundColor: navy,
          elevation: 0,
          centerTitle: false),
      cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
    );
    return MaterialApp(
      title: 'DocuMind AI',
      debugShowCheckedModeBanner: false,
      theme: base,
      home: const AppShell(),
    );
  }
}

class DocItem {
  final String name;
  final String type;
  final String size;
  final String date;
  final String status;
  final String? path;
  final String? analysisJson;
  const DocItem(this.name, this.type, this.size, this.date, this.status,
      {this.path, this.analysisJson});

  DocItem copyWith({String? status, String? analysisJson}) => DocItem(
      name, type, size, date, status ?? this.status,
      path: path, analysisJson: analysisJson ?? this.analysisJson);

  Map<String, dynamic> toJson() => {
        'name': name, 'type': type, 'size': size, 'date': date,
        'status': status, 'path': path, 'analysisJson': analysisJson
      };
  factory DocItem.fromJson(Map<String, dynamic> json) => DocItem(
        json['name'] ?? 'Untitled document',
        json['type'] ?? 'FILE',
        json['size'] ?? '—',
        json['date'] ?? 'Recently added',
        json['status'] ?? 'Ready',
        path: json['path'],
        analysisJson: json['analysisJson'],
      );
}


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

class PageBody extends StatelessWidget {
  final Widget child;
  const PageBody({super.key, required this.child});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        child: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: child)),
      );
}

Widget heading(String title, String subtitle, {Widget? trailing}) => Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: navy,
                  letterSpacing: -0.8)),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: muted)),
        ])),
        if (trailing != null) trailing,
      ],
    );

Widget sectionTitle(String title, {String? action, VoidCallback? onTap}) =>
    Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 13),
      child: Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: navy))),
        if (action != null)
          TextButton(
              onPressed: onTap,
              child: Text(action,
                  style: const TextStyle(
                      color: blue, fontWeight: FontWeight.w700))),
      ]),
    );

class HomePage extends StatelessWidget {
  final List<DocItem> docs;
  final VoidCallback onUpload;
  final ValueChanged<int> onNavigate;
  final ValueChanged<DocItem> onOpen;
  const HomePage(
      {super.key,
      required this.docs,
      required this.onUpload,
      required this.onNavigate,
      required this.onOpen});

  @override
  Widget build(BuildContext context) => PageBody(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading('Good afternoon 👋', 'Your documents, understood in seconds.'),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF172B65),
                  Color(0xFF315FE5),
                  Color(0xFF5485FF)
                ]),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                  color: blue.withOpacity(.18),
                  blurRadius: 25,
                  offset: const Offset(0, 12))
            ],
          ),
          child: Stack(children: [
            Positioned(
                right: -15,
                top: -25,
                child: Icon(Icons.auto_awesome_rounded,
                    size: 150, color: Colors.white.withOpacity(.08))),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.14),
                      borderRadius: BorderRadius.circular(30)),
                  child: const Text('YOUR AI DOCUMENT WORKSPACE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w800))),
              const SizedBox(height: 18),
              const Text('Make sense of every document.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.8)),
              const SizedBox(height: 10),
              Text('Summarize, discover key details and spot risks with AI.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(.78),
                      fontSize: 12,
                      height: 1.5)),
              const SizedBox(height: 20),
              FilledButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Upload a document'),
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF234CCB),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13))),
            ]),
          ]),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
              child: StatCard(
                  icon: Icons.folder_copy_rounded,
                  value: '${docs.length}',
                  label: 'Documents',
                  tint: const Color(0xFFEAF0FF),
                  color: blue)),
          const SizedBox(width: 10),
              Expanded(
              child: StatCard(
                  icon: Icons.check_circle_rounded,
                  value: '${docs.where((d) => d.analysisJson != null).length}',
                  label: 'Analyzed',
                  tint: const Color(0xFFEAF0FF),
                  color: blue)),
        ]),
        sectionTitle('Recent documents',
            action: 'View all', onTap: () => onNavigate(1)),
        ...docs
            .take(3)
            .map((d) => DocumentTile(doc: d, onTap: () => onOpen(d))),
        sectionTitle('Explore your workspace'),
        GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 11,
            crossAxisSpacing: 11,
            childAspectRatio: 1.55,
            children: [
              ActionTile(
                  icon: Icons.auto_awesome,
                  title: 'Ask your documents',
                  subtitle: 'Get instant answers',
                  onTap: () => onNavigate(3)),
              ActionTile(
                  icon: Icons.compare_arrows_rounded,
                  title: 'Compare files',
                  subtitle: 'Find what changed',
                  onTap: () => onNavigate(5)),
              ActionTile(
                  icon: Icons.insights_rounded,
                  title: 'Insights',
                  subtitle: 'See key patterns',
                  onTap: () => onNavigate(4)),
              ActionTile(
                  icon: Icons.shield_outlined,
                  title: 'Risk review',
                  subtitle: 'Spot important clauses',
                  onTap: () => onNavigate(2)),
            ]),
      ]));
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color tint, color;
  const StatCard(
      {super.key,
      required this.icon,
      required this.value,
      required this.label,
      required this.tint,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(19)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: tint, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 17)),
        const SizedBox(height: 10),
        Text(value,
            style: const TextStyle(
                fontSize: 21, fontWeight: FontWeight.w800, color: navy)),
        Text(label, style: const TextStyle(fontSize: 10, color: muted)),
      ]));
}

class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const ActionTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: blue, size: 22),
                const SizedBox(height: 9),
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: navy)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(fontSize: 10, color: muted)),
              ])));
}

class DocumentTile extends StatelessWidget {
  final DocItem doc;
  final VoidCallback? onTap;
  const DocumentTile({super.key, required this.doc, this.onTap});
  @override
  Widget build(BuildContext context) {
    final color =
        doc.type == 'PDF' ? const Color(0xFFE65E68) : const Color(0xFF4778E8);
    return Card(
        margin: const EdgeInsets.only(bottom: 9),
        child: ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
          leading: Container(
              width: 43,
              height: 47,
              decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insert_drive_file_rounded,
                        color: color, size: 20),
                    Text(doc.type,
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: color))
                  ])),
          title: Text(doc.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: navy)),
          subtitle: Text('${doc.size}  ·  ${doc.date}',
              style: const TextStyle(fontSize: 10, color: muted)),
          trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                  color: doc.status == 'Analyzed'
                      ? const Color(0xFFEAF7F2)
                      : const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(doc.status,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: doc.status == 'Analyzed'
                          ? const Color(0xFF15966D)
                          : const Color(0xFFBD8126)))),
        ));
  }
}

class LibraryPage extends StatefulWidget {
  final List<DocItem> docs;
  final VoidCallback onUpload;
  final ValueChanged<DocItem> onOpen;
  const LibraryPage(
      {super.key,
      required this.docs,
      required this.onUpload,
      required this.onOpen});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String query = '';
  String filter = 'All';
  @override
  Widget build(BuildContext context) {
    final items = widget.docs
        .where((d) =>
            d.name.toLowerCase().contains(query.toLowerCase()) &&
            (filter == 'All' || d.type == filter))
        .toList();
    return PageBody(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading(
          'Document library', '${widget.docs.length} files in your workspace',
          trailing: IconButton(
              onPressed: widget.onUpload,
              icon: const Icon(Icons.add_circle, color: blue, size: 30))),
      const SizedBox(height: 20),
      TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: InputDecoration(
              hintText: 'Search documents...',
              prefixIcon: const Icon(Icons.search_rounded, color: muted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14))),
      const SizedBox(height: 13),
      Wrap(
          spacing: 8,
          children: ['All', 'PDF', 'DOCX', 'TXT']
              .map((f) => ChoiceChip(
                  label: Text(f),
                  selected: filter == f,
                  onSelected: (_) => setState(() => filter = f),
                  selectedColor: const Color(0xFFE4EBFF),
                  labelStyle: TextStyle(
                      color: filter == f ? blue : muted,
                      fontWeight: FontWeight.w700)))
              .toList()),
      sectionTitle('Your files'),
      if (items.isEmpty)
        const EmptyState(
            icon: Icons.folder_open_rounded,
            title: 'No documents found',
            subtitle: 'Try another search or upload a document.'),
      ...items.map((d) => DocumentTile(doc: d, onTap: () => widget.onOpen(d))),
    ]));
  }
}

class AnalysisPage extends StatefulWidget {
  final List<DocItem> docs;
  final String? selectedPath;
  final ValueChanged<String?> onSelectPath;
  final ValueChanged<DocItem> onUpdate;
  const AnalysisPage({
    super.key,
    required this.docs,
    required this.selectedPath,
    required this.onSelectPath,
    required this.onUpdate,
  });
  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  int tab = 0;
  int selectedIndex = 0;
  bool busy = false;
  String? error;
  Map<String, dynamic>? result;

  @override
  void initState() {
    super.initState();
    if (widget.selectedPath != null) {
      final index = widget.docs.indexWhere((d) => d.path == widget.selectedPath);
      if (index >= 0) selectedIndex = index;
    }
  }

  @override
  void didUpdateWidget(covariant AnalysisPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPath != widget.selectedPath && widget.selectedPath != null) {
      final nextIndex = widget.docs.indexWhere((d) => d.path == widget.selectedPath);
      if (nextIndex >= 0) {
        selectedIndex = nextIndex;
        result = null;
        error = null;
      }
    }
    if (selectedIndex >= widget.docs.length) selectedIndex = 0;
  }

  Future<void> _analyze(DocItem doc) async {
    if (doc.path == null || doc.path!.isEmpty) {
      setState(() => error = 'This item has no local file attached. Please upload the original document again.');
      return;
    }
    setState(() { busy = true; error = null; result = null; });
    try {
      final text = await DocumentTextExtractor.extract(doc.path!, doc.type);
      if (text.trim().length < 40) {
        throw Exception('No readable text was found. If this is a scanned PDF, OCR is required before it can be analyzed.');
      }
      final analysis = await OpenRouterDocumentAI.analyze(
        fileName: doc.name, fileType: doc.type, text: text);
      final encoded = jsonEncode(analysis);
      final updated = doc.copyWith(status: 'Analyzed', analysisJson: encoded);
      widget.onUpdate(updated);
      if (mounted) setState(() => result = analysis);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.docs.isEmpty ? null : widget.docs[selectedIndex.clamp(0, widget.docs.length - 1)];
    if (doc != null && result == null && doc.analysisJson != null) {
      try { result = jsonDecode(doc.analysisJson!) as Map<String, dynamic>; } catch (_) {}
    }
    final data = result;
    final tabs = ['Overview', 'Key details', 'Risks', 'Actions'];
    return PageBody(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading('Document analysis', 'Extract facts, understand obligations and identify risks.'),
      const SizedBox(height: 18),
      if (doc == null)
        const EmptyState(icon: Icons.document_scanner_rounded, title: 'Add a document to begin',
          subtitle: 'Upload a PDF, DOCX, TXT or RTF file. The analysis will be generated from its actual text.')
      else ...[
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.description_rounded, color: blue, size: 25),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(doc.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: navy, fontSize: 12)),
                Text('${doc.size} · ${doc.type} · ${doc.status}',
                  style: const TextStyle(color: muted, fontSize: 10))
              ]))
            ]),
            if (widget.docs.length > 1) ...[
              const SizedBox(height: 10),
              DropdownButton<int>(
                value: selectedIndex.clamp(0, widget.docs.length - 1),
                isExpanded: true,
                items: List.generate(widget.docs.length, (i) => DropdownMenuItem(
                  value: i, child: Text(widget.docs[i].name, overflow: TextOverflow.ellipsis))),
                onChanged: busy ? null : (v) => setState(() {
                  selectedIndex = v ?? 0;
                  widget.onSelectPath(widget.docs[selectedIndex].path);
                  result = null; error = null;
                }),
              )
            ],
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: busy ? null : () => _analyze(doc),
              icon: busy ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome_rounded),
              label: Text(busy ? 'Reading and analyzing document…' : data == null ? 'Analyze with AI' : 'Run analysis again'),
              style: FilledButton.styleFrom(backgroundColor: blue, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            )),
            if (busy) const Padding(padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(color: blue, backgroundColor: pale)),
          ]),
        ),
        if (error != null) ...[
          const SizedBox(height: 14),
          Container(width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(14)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFD64D5A), size: 19),
              const SizedBox(width: 9), Expanded(child: Text(error!,
                style: const TextStyle(color: Color(0xFF9C3540), fontSize: 11, height: 1.5)))
            ]))
        ],
        if (data != null) ...[
          const SizedBox(height: 18),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.verified_rounded, color: blue, size: 18),
                SizedBox(width: 7), Text('Analysis generated from document text',
                  style: TextStyle(color: navy, fontSize: 12, fontWeight: FontWeight.w800))]),
              const SizedBox(height: 13),
              Wrap(spacing: 5, children: List.generate(tabs.length, (i) => ChoiceChip(
                label: Text(tabs[i]), selected: tab == i, onSelected: (_) => setState(() => tab = i),
                selectedColor: const Color(0xFFE7EDFF),
                labelStyle: TextStyle(fontSize: 10, color: tab == i ? blue : muted, fontWeight: FontWeight.w700)))),
              const SizedBox(height: 16),
              if (tab == 0) ...[
                Text((data['document_type'] ?? 'Document').toString().toUpperCase(),
                  style: const TextStyle(color: blue, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: .8)),
                const SizedBox(height: 8),
                const Text('Executive summary', style: TextStyle(fontWeight: FontWeight.w800, color: navy, fontSize: 15)),
                const SizedBox(height: 7),
                Text((data['summary'] ?? 'No summary returned.').toString(),
                  style: const TextStyle(color: Color(0xFF58647A), height: 1.6, fontSize: 12)),
                if (data['confidence_notes'] != null) ...[
                  const SizedBox(height: 12),
                  Text('Review note: ${data['confidence_notes']}',
                    style: const TextStyle(color: muted, fontSize: 10, height: 1.5))
                ]
              ] else if (tab == 1) ...[
                _stringList(data['key_details'], empty: 'No key details were identified.')
              ] else if (tab == 2) ...[
                _riskList(data['risks'])
              ] else ...[
                _stringList(data['action_items'], empty: 'No action items were identified.')
              ]
            ]))
        ] else if (!busy && error == null) ...[
          const SizedBox(height: 16),
          const Text('Your analysis will appear here after you run the document through the AI model.',
            style: TextStyle(color: muted, fontSize: 11, height: 1.5))
        ],
        const SizedBox(height: 14),
        const Text('AI-generated analysis can miss context or misinterpret clauses. Verify important facts and seek professional advice for legal, financial or medical decisions.',
          style: TextStyle(color: muted, fontSize: 10, height: 1.5))
      ]
    ]));
  }

  Widget _stringList(dynamic values, {required String empty}) {
    final items = values is List ? values : const [];
    if (items.isEmpty) return Text(empty, style: const TextStyle(color: muted, fontSize: 11));
    return Column(children: items.map((v) => Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: pale, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.check_circle_outline_rounded, color: blue, size: 16),
        const SizedBox(width: 8), Expanded(child: Text(v.toString(),
          style: const TextStyle(color: navy, fontSize: 11, height: 1.5)))
      ])
    )).toList());
  }

  Widget _riskList(dynamic values) {
    final items = values is List ? values : const [];
    if (items.isEmpty) return const Text('No risks were identified by the model. This is not a guarantee that the document is risk-free.',
      style: TextStyle(color: muted, fontSize: 11, height: 1.5));
    return Column(children: items.map((v) {
      final item = v is Map ? v : <String, dynamic>{'title': v.toString()};
      final level = (item['level'] ?? 'Review').toString();
      final color = level.toLowerCase().contains('high') ? const Color(0xFFD94F5C)
        : level.toLowerCase().contains('medium') ? const Color(0xFFE19A35) : blue;
      return RiskLine(level: level, title: (item['title'] ?? 'Review item').toString(),
        detail: (item['detail'] ?? '').toString(), color: color);
    }).toList());
  }
}

class DocumentTextExtractor {
  static Future<String> extract(String path, String type) async {
    final file = File(path);
    if (!await file.exists()) throw Exception('The original file is no longer available on this device. Please upload it again.');
    final bytes = await file.readAsBytes();
    final ext = type.toUpperCase();
    String text;
    if (ext == 'PDF') {
      final pdf = sf.PdfDocument(inputBytes: bytes);
      try { text = sf.PdfTextExtractor(pdf).extractText(); }
      finally { pdf.dispose(); }
    } else if (ext == 'DOCX') {
      final archive = ZipDecoder().decodeBytes(bytes);
      final entries = archive.files.where((f) => f.name == 'word/document.xml').toList();
      if (entries.isEmpty) throw Exception('Could not find the text body inside this DOCX file.');
      final entry = entries.first;
      final xml = XmlDocument.parse(utf8.decode(entry.content as List<int>, allowMalformed: true));
      text = xml.descendants.whereType<XmlElement>()
        .where((e) => e.name.local == 't').map((e) => e.innerText).join(' ');
    } else if (ext == 'TXT') {
      text = utf8.decode(bytes, allowMalformed: true);
    } else if (ext == 'RTF') {
      text = utf8.decode(bytes, allowMalformed: true)
        .replaceAll(RegExp(r"\\'[0-9a-fA-F]{2}"), ' ')
        .replaceAll(RegExp(r'\\[a-zA-Z]+-?\d* ?'), ' ')
        .replaceAll(RegExp(r'[{}]'), ' ')
        .replaceAll(RegExp(r'\\\\'), ' ');
    } else {
      throw Exception('Legacy .doc files are not supported yet. Save this file as .docx or PDF and upload it again.');
    }
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    if (text.isEmpty) throw Exception('No readable text was extracted from this file.');
    if (text.length > 65000) text = '${text.substring(0, 65000)}\n[Document truncated for analysis due to context limits.]';
    return text;
  }
}

class OpenRouterDocumentAI {
  static String get _apiKey => dotenv.env['OPENROUTER_API_KEY']?.trim() ?? '';
  static String get _model =>
      dotenv.env['OPENROUTER_MODEL']?.trim().isNotEmpty == true
          ? dotenv.env['OPENROUTER_MODEL']!.trim()
          : 'openrouter/free';

  static Future<String> _complete({
    required String system,
    required String user,
    double temperature = 0.2,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('OpenRouter API key is missing. Add OPENROUTER_API_KEY to the .env file in the project root. For production, move AI calls to a secure backend.');
    }
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com/aminemtar/Document-Analyser',
        'X-Title': 'DocuMind AI',
      },
      body: jsonEncode({
        'model': _model,
        'temperature': temperature,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
      }),
    ).timeout(const Duration(seconds: 90));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AI service returned ${response.statusCode}: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final content = payload['choices']?[0]?['message']?['content'];
    if (content is! String || content.trim().isEmpty) {
      throw Exception('The AI service returned an empty response.');
    }
    return content.trim();
  }

  static Map<String, dynamic> _decodeJson(String content) {
    final cleaned = content
        .replaceFirst(RegExp(r'^\x60\x60\x60(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*\x60\x60\x60$'), '');
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('The AI response was not valid structured JSON. Please run it again.');
    }
  }

  static Future<Map<String, dynamic>> analyze({
    required String fileName,
    required String fileType,
    required String text,
  }) async {
    final content = await _complete(
      system: 'You are a careful document analyst. Only report facts supported by the supplied text. Never invent names, dates, amounts, clauses or risks. If something is absent or unclear, say so. Return valid JSON only with keys: document_type (string), summary (string), key_details (array of strings), risks (array of objects with level, title, detail), action_items (array of strings), confidence_notes (string). Separate factual observations from recommendations. Do not present legal conclusions as professional advice.',
      user: 'Analyze this real uploaded document. Filename: $fileName. Format: $fileType.\n\nDOCUMENT TEXT:\n$text',
    );
    return _decodeJson(content);
  }

  static Future<String> ask({
    required String question,
    required List<Map<String, String>> documents,
  }) {
    final context = documents.map((d) =>
      'FILE: ${d['name']}\nCONTENT:\n${d['text']}'
    ).join('\n\n--- NEXT DOCUMENT ---\n\n');
    return _complete(
      system: 'You are DocuMind, a precise assistant that answers questions using only the provided uploaded document text. Cite the source filename when possible. If the answer is not present in the supplied files, say clearly that the uploaded documents do not contain enough information. Never invent facts. Be concise but useful.',
      user: 'QUESTION:\n$question\n\nUPLOADED DOCUMENTS:\n$context',
      temperature: 0.1,
    );
  }

  static Future<Map<String, dynamic>> compare({
    required String firstName,
    required String firstText,
    required String secondName,
    required String secondText,
  }) async {
    final content = await _complete(
      system: 'You compare two real documents carefully. Only report differences supported by the supplied text. Do not assume that missing text means a clause was removed unless the comparison supports that conclusion. Return valid JSON only with keys: summary (string), similarities (array of strings), differences (array of objects with topic, document_a, document_b, significance), changed_dates_or_amounts (array of strings), review_points (array of strings). State when a value is not found. Do not give professional legal advice.',
      user: 'Compare these two uploaded documents.\n\nDOCUMENT A: $firstName\n$firstText\n\nDOCUMENT B: $secondName\n$secondText',
    );
    return _decodeJson(content);
  }
}

class MiniMetric extends StatelessWidget {
  final String value, label;
  const MiniMetric({super.key, required this.value, required this.label});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(
                color: blue, fontSize: 19, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: muted, fontSize: 9))
      ]);
}

class DetailLine extends StatelessWidget {
  final String label, value;
  const DetailLine({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 112,
            child: Text(label,
                style: const TextStyle(color: muted, fontSize: 11))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: navy, fontWeight: FontWeight.w600, fontSize: 11)))
      ]));
}

class RiskLine extends StatelessWidget {
  final String level, title, detail;
  final Color color;
  const RiskLine(
      {super.key,
      required this.level,
      required this.title,
      required this.detail,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withOpacity(.07),
          borderRadius: BorderRadius.circular(13)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(level.toUpperCase(),
            style: TextStyle(
                fontSize: 8,
                letterSpacing: .8,
                fontWeight: FontWeight.w900,
                color: color)),
        const SizedBox(height: 5),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 12, color: navy)),
        const SizedBox(height: 4),
        Text(detail,
            style: const TextStyle(fontSize: 10, color: muted, height: 1.45))
      ]));
}

class AssistantPage extends StatefulWidget {
  final List<DocItem> docs;
  const AssistantPage({super.key, required this.docs});
  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  final messages = <Map<String, String>>[
    {'role': 'ai', 'text': 'Ask a question about your uploaded files. I’ll use their extracted text and name the source when possible.'},
  ];
  bool busy = false;
  String? error;

  Future<void> send() async {
    final question = controller.text.trim();
    if (question.isEmpty || busy) return;
    if (widget.docs.isEmpty) {
      setState(() {
        messages.add({'role': 'user', 'text': question});
        messages.add({'role': 'ai', 'text': 'Upload a PDF, DOCX, TXT or RTF file first. I need real document content to answer questions.'});
        controller.clear();
      });
      return;
    }
    setState(() {
      messages.add({'role': 'user', 'text': question});
      controller.clear();
      busy = true;
      error = null;
    });
    try {
      final available = <Map<String, String>>[];
      for (final doc in widget.docs) {
        if (doc.path == null || doc.path!.isEmpty) continue;
        try {
          final text = await DocumentTextExtractor.extract(doc.path!, doc.type);
          available.add({
            'name': doc.name,
            'text': text.length > 18000 ? text.substring(0, 18000) : text,
          });
        } catch (_) {
          // A single unavailable file should not prevent answers from other files.
        }
      }
      if (available.isEmpty) {
        throw Exception('No readable uploaded files were found. Re-import the original documents and try again.');
      }
      final answer = await OpenRouterDocumentAI.ask(
        question: question,
        documents: available,
      );
      if (mounted) setState(() => messages.add({'role': 'ai', 'text': answer}));
    } catch (e) {
      if (mounted) setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        messages.add({'role': 'ai', 'text': 'I couldn’t complete that request. ${error!}'});
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading('AI assistant', 'Ask questions across your uploaded documents.'),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.folder_copy_outlined, color: blue, size: 16),
          const SizedBox(width: 7),
          Text('${widget.docs.length} real file(s) available',
            style: const TextStyle(color: muted, fontSize: 11)),
        ]),
      ]),
    ),
    Expanded(
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        itemCount: messages.length,
        itemBuilder: (context, i) {
          final m = messages[i];
          final user = m['role'] == 'user';
          return Align(
            alignment: user ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 330),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: user ? blue : Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(m['text']!,
                style: TextStyle(color: user ? Colors.white : navy, fontSize: 12, height: 1.5)),
            ),
          );
        },
      ),
    ),
    if (busy) const LinearProgressIndicator(color: blue, backgroundColor: pale),
    Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Row(children: [
        Expanded(child: TextField(
          controller: controller,
          enabled: !busy,
          onSubmitted: (_) => send(),
          decoration: InputDecoration(
            hintText: 'Ask about your uploaded files…',
            filled: true,
            fillColor: pale,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          ),
        )),
        const SizedBox(width: 9),
        IconButton.filled(
          onPressed: busy ? null : send,
          style: IconButton.styleFrom(backgroundColor: blue, foregroundColor: Colors.white),
          icon: const Icon(Icons.arrow_upward_rounded),
        ),
      ]),
    ),
  ]);
}

class InsightsPage extends StatelessWidget {
  final List<DocItem> docs;
  const InsightsPage({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    final analyzed = docs.where((d) => d.analysisJson != null).toList();
    final typeCounts = <String, int>{};
    for (final doc in docs) {
      typeCounts[doc.type] = (typeCounts[doc.type] ?? 0) + 1;
    }
    return PageBody(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading('Insights', 'Live statistics from your own document library.'),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: StatCard(
          icon: Icons.description_rounded,
          value: '${docs.length}',
          label: 'Uploaded files',
          tint: const Color(0xFFEAF0FF),
          color: blue,
        )),
        const SizedBox(width: 10),
        Expanded(child: StatCard(
          icon: Icons.check_circle_rounded,
          value: '${analyzed.length}',
          label: 'AI analyzed',
          tint: const Color(0xFFEAF0FF),
          color: blue,
        )),
      ]),
      sectionTitle('Your file formats'),
      if (docs.isEmpty)
        const EmptyState(
          icon: Icons.insights_rounded,
          title: 'No activity yet',
          subtitle: 'Upload your first real document to see library insights here.',
        )
      else
        ...typeCounts.entries.map((entry) => CategoryBar(
          label: entry.key,
          value: entry.value / docs.length,
          count: '${entry.value} file(s)',
          color: blue,
        )),
      sectionTitle('Recently analyzed'),
      if (analyzed.isEmpty)
        const Text('No document has been analyzed yet.',
          style: TextStyle(color: muted, fontSize: 11))
      else
        ...analyzed.take(5).map((doc) => DocumentTile(doc: doc)),
    ]));
  }
}

class CategoryBar extends StatelessWidget {
  final String label, count;
  final double value;
  final Color color;
  const CategoryBar(
      {super.key,
      required this.label,
      required this.value,
      required this.count,
      required this.color});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: navy, fontWeight: FontWeight.w700, fontSize: 11))),
          Text(count, style: const TextStyle(color: muted, fontSize: 10))
        ]),
        const SizedBox(height: 8),
        ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white,
                color: color))
      ]));
}

class ComparePage extends StatefulWidget {
  final List<DocItem> docs;
  const ComparePage({super.key, required this.docs});
  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  int a = 0, b = 1;
  bool busy = false;
  String? error;
  Map<String, dynamic>? comparison;

  Future<void> _compare() async {
    if (widget.docs.length < 2 || a == b || busy) return;
    final first = widget.docs[a];
    final second = widget.docs[b];
    if (first.path == null || second.path == null) {
      setState(() => error = 'One of the selected files is no longer available. Please re-import it.');
      return;
    }
    setState(() { busy = true; error = null; comparison = null; });
    try {
      final firstText = await DocumentTextExtractor.extract(first.path!, first.type);
      final secondText = await DocumentTextExtractor.extract(second.path!, second.type);
      if (firstText.length < 20 || secondText.length < 20) {
        throw Exception('One of the files does not contain enough readable text to compare.');
      }
      final result = await OpenRouterDocumentAI.compare(
        firstName: first.name,
        firstText: firstText.length > 28000 ? firstText.substring(0, 28000) : firstText,
        secondName: second.name,
        secondText: secondText.length > 28000 ? secondText.substring(0, 28000) : secondText,
      );
      if (mounted) setState(() => comparison = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void didUpdateWidget(covariant ComparePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (a >= widget.docs.length) a = 0;
    if (b >= widget.docs.length) b = widget.docs.length > 1 ? 1 : 0;
    if (oldWidget.docs.length != widget.docs.length) comparison = null;
  }

  @override
  Widget build(BuildContext context) => PageBody(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading('Compare documents', 'Find real differences between two uploaded files.'),
      const SizedBox(height: 20),
      if (widget.docs.length < 2)
        const EmptyState(
          icon: Icons.compare_arrows_rounded,
          title: 'Add two documents',
          subtitle: 'Import at least two real files into your library to compare their contents.',
        )
      else ...[
        _selector('Document A', a, (v) => setState(() { a = v; comparison = null; error = null; })),
        const SizedBox(height: 12),
        _selector('Document B', b, (v) => setState(() { b = v; comparison = null; error = null; })),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: busy || a == b ? null : _compare,
          icon: busy
            ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.compare_arrows_rounded),
          label: Text(busy ? 'Extracting and comparing…' : 'Compare actual contents'),
          style: FilledButton.styleFrom(backgroundColor: blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
        )),
        if (a == b)
          const Padding(padding: EdgeInsets.only(top: 9), child: Text('Choose two different files.',
            style: TextStyle(color: muted, fontSize: 11))),
        if (error != null) ...[
          const SizedBox(height: 14),
          Container(width: double.infinity, padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(13)),
            child: Text(error!, style: const TextStyle(color: Color(0xFF9C3540), fontSize: 11, height: 1.5))),
        ],
        if (comparison != null) ...[
          const SizedBox(height: 20),
          _resultSection('Comparison summary', comparison!['summary']),
          _resultList('Similarities', comparison!['similarities']),
          _differenceList(comparison!['differences']),
          _resultList('Changed dates and amounts', comparison!['changed_dates_or_amounts']),
          _resultList('Points to review', comparison!['review_points']),
          const SizedBox(height: 10),
          const Text('AI comparison is based on extracted text only. Check the original files before relying on any finding.',
            style: TextStyle(color: muted, fontSize: 10, height: 1.5)),
        ],
      ],
    ]),
  );

  Widget _selector(String label, int value, ValueChanged<int> onChanged) =>
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        DropdownButton<int>(
          value: value.clamp(0, widget.docs.length - 1).toInt(),
          isExpanded: true,
          underline: const SizedBox(),
          items: List.generate(widget.docs.length, (i) => DropdownMenuItem(
            value: i,
            child: Text(widget.docs[i].name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
          )),
          onChanged: busy ? null : (v) { if (v != null) onChanged(v); },
        ),
      ]),
    );

  Widget _resultSection(String title, dynamic value) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 13)),
      const SizedBox(height: 7),
      Text((value ?? 'No summary returned.').toString(), style: const TextStyle(color: Color(0xFF58647A), fontSize: 11, height: 1.55)),
    ]),
  );

  Widget _resultList(String title, dynamic values) {
    final items = values is List ? values : const [];
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.circle, color: blue, size: 7),
            const SizedBox(width: 8),
            Expanded(child: Text(item.toString(), style: const TextStyle(color: Color(0xFF58647A), fontSize: 11, height: 1.5))),
          ]),
        )),
      ]),
    );
  }

  Widget _differenceList(dynamic values) {
    final items = values is List ? values : const [];
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Differences', style: TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 8),
        ...items.map((entry) {
          final item = entry is Map ? entry : <String, dynamic>{'topic': entry.toString()};
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: pale, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((item['topic'] ?? 'Difference').toString(), style: const TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 11)),
              const SizedBox(height: 6),
              Text('A · ${item['document_a'] ?? 'Not found'}', style: const TextStyle(color: Color(0xFF58647A), fontSize: 10, height: 1.5)),
              Text('B · ${item['document_b'] ?? 'Not found'}', style: const TextStyle(color: Color(0xFF58647A), fontSize: 10, height: 1.5)),
              if (item['significance'] != null) ...[
                const SizedBox(height: 5),
                Text('Why it matters: ${item['significance']}', style: const TextStyle(color: navy, fontSize: 10, height: 1.5, fontWeight: FontWeight.w600)),
              ],
            ]),
          );
        }),
      ]),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => PageBody(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading('Your profile', 'Manage your workspace preferences.'),
        const SizedBox(height: 22),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(22)),
            child: const Column(children: [
              CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFFE7EDFF),
                  child: Text('M',
                      style: TextStyle(
                          color: blue,
                          fontSize: 27,
                          fontWeight: FontWeight.w800))),
              SizedBox(height: 12),
              Text('My workspace',
                  style: TextStyle(
                      color: navy, fontWeight: FontWeight.w800, fontSize: 17)),
              SizedBox(height: 4),
              Text('Free plan · Personal account',
                  style: TextStyle(color: muted, fontSize: 11)),
            ])),
        sectionTitle('Preferences'),
        const SettingsRow(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: 'English',
            trailing: 'EN'),
        const SettingsRow(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Manage alerts'),
        const SettingsRow(
            icon: Icons.lock_outline_rounded,
            title: 'Privacy & security',
            subtitle: 'Your files stay in your workspace'),
        const SettingsRow(
            icon: Icons.help_outline_rounded,
            title: 'Help & support',
            subtitle: 'Get assistance'),
        const SizedBox(height: 18),
        const Center(
            child: Text('DocuMind AI  ·  Version 1.0.0',
                style: TextStyle(color: muted, fontSize: 10))),
      ]));
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final String? trailing;
  const SettingsRow(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      this.trailing});
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
          leading: Icon(icon, color: blue),
          title: Text(title,
              style: const TextStyle(
                  color: navy, fontWeight: FontWeight.w700, fontSize: 12)),
          subtitle: Text(subtitle,
              style: const TextStyle(color: muted, fontSize: 10)),
          trailing: Text(trailing ?? '›',
              style: const TextStyle(color: muted, fontSize: 16))));
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Icon(icon, size: 36, color: blue),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(
                color: navy, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 6),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 11, height: 1.5))
      ]));
}
