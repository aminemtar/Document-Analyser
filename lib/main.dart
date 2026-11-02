import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:xml/xml.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const navy = Color(0xFF101B3D);
const blue = Color(0xFF3568F5);
const pale = Color(0xFFF3F6FC);
const muted = Color(0xFF8792A8);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf'],
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.first;
    final ext = (file.extension ?? 'FILE').toUpperCase();
    final size = file.size < 1024 * 1024
        ? '${(file.size / 1024).toStringAsFixed(0)} KB'
        : '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB';
    setState(() {
      documents.insert(0, DocItem(file.name, ext, size, 'Just now', 'Ready', path: file.path));
      selected = 1;
    });
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
          onNavigate: (i) => setState(() => selected = i)),
      LibraryPage(
          docs: documents,
          onUpload: _pickDocument,
          onOpen: (doc) => setState(() => selected = 2)),
      AnalysisPage(docs: documents, onUpdate: (updated) async {
        final index = documents.indexWhere((d) => d.name == updated.name && d.path == updated.path);
        if (index >= 0) { documents[index] = updated; await _saveDocuments(); if (mounted) setState(() {}); }
      }),
      const AssistantPage(),
      const InsightsPage(),
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
  const HomePage(
      {super.key,
      required this.docs,
      required this.onUpload,
      required this.onNavigate});

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
          const Expanded(
              child: StatCard(
                  icon: Icons.check_circle_rounded,
                  value: '2',
                  label: 'Analyzed',
                  tint: Color(0xFFE8F7F2),
                  color: Color(0xFF16A77A))),
          const SizedBox(width: 10),
          const Expanded(
              child: StatCard(
                  icon: Icons.bolt_rounded,
                  value: '86%',
                  label: 'Time saved',
                  tint: Color(0xFFFFF4E5),
                  color: Color(0xFFE99A28))),
        ]),
        sectionTitle('Recent documents',
            action: 'View all', onTap: () => onNavigate(1)),
        ...docs
            .take(3)
            .map((d) => DocumentTile(doc: d, onTap: () => onNavigate(2))),
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
  final ValueChanged<DocItem> onUpdate;
  const AnalysisPage({super.key, required this.docs, required this.onUpdate});
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
  void didUpdateWidget(covariant AnalysisPage oldWidget) {
    super.didUpdateWidget(oldWidget);
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
        .replaceAll(RegExp(r'\\[a-zA-Z]+-?\\d* ?'), ' ')
        .replaceAll(RegExp(r'[{}]'), ' ')
        .replaceAll(RegExp(r'\\\\'), ' ');
    } else {
      throw Exception('Legacy .doc files are not supported yet. Save this file as .docx or PDF and upload it again.');
    }
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll(RegExp(r'\n{3,}'), '\\n\\n').trim();
    if (text.isEmpty) throw Exception('No readable text was extracted from this file.');
    if (text.length > 65000) text = '${text.substring(0, 65000)}\n[Document truncated for analysis due to context limits.]';
    return text;
  }
}

class OpenRouterDocumentAI {
  static const _apiKey = String.fromEnvironment('OPENROUTER_API_KEY');
  static const _model = String.fromEnvironment('OPENROUTER_MODEL', defaultValue: 'openrouter/free');

  static Future<Map<String, dynamic>> analyze({
    required String fileName, required String fileType, required String text}) async {
    if (_apiKey.isEmpty) {
      throw Exception('OpenRouter API key is missing. Run with --dart-define=OPENROUTER_API_KEY=YOUR_KEY. For production, move AI calls to a secure backend.');
    }
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com/aminemtar/Document-Analyser', 'X-Title': 'DocuMind AI'},
      body: jsonEncode({
        'model': _model,
        'temperature': 0.2,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': 'You are a careful document analyst. Only report facts supported by the supplied text. Never invent names, dates, amounts, clauses or risks. If something is absent or unclear, say so. Return valid JSON only with keys: document_type (string), summary (string), key_details (array of strings), risks (array of objects with level, title, detail), action_items (array of strings), confidence_notes (string). Separate factual observations from recommendations. Do not present legal conclusions as professional advice.'},
          {'role': 'user', 'content': 'Analyze this document. Filename: $fileName. Format: $fileType.\\n\\nDOCUMENT TEXT:\\n$text'}
        ]
      }),
    ).timeout(const Duration(seconds: 90));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AI service returned ${response.statusCode}: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final content = payload['choices']?[0]?['message']?['content'];
    if (content is! String || content.trim().isEmpty) throw Exception('The AI service returned an empty analysis.');
    final cleaned = content.trim().replaceFirst(RegExp(r'^\`\`\`(?:json)?\\s*'), '').replaceFirst(RegExp(r'\\s*\`\`\`$'), '');
    try { return jsonDecode(cleaned) as Map<String, dynamic>; }
    catch (_) { throw Exception('The AI response was not valid structured JSON. Please run the analysis again.'); }
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
  const AssistantPage({super.key});
  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final controller = TextEditingController();
  final messages = <Map<String, String>>[
    {
      'role': 'ai',
      'text':
          'Hi! I’m your document assistant. Ask me to explain a clause, summarize a file, or find information across your documents.'
    },
  ];
  void send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add({'role': 'user', 'text': text});
      messages.add({
        'role': 'ai',
        'text':
            'I can help with that once document AI is connected. This preview currently demonstrates the chat experience; no document content is being sent to an AI model yet.'
      });
      controller.clear();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 12),
            child:
                heading('AI assistant', 'Ask questions about your documents.')),
        Expanded(
            child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final m = messages[i];
                  final user = m['role'] == 'user';
                  return Align(
                      alignment:
                          user ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                          constraints: const BoxConstraints(maxWidth: 310),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: user ? blue : Colors.white,
                              borderRadius: BorderRadius.circular(18)),
                          child: Text(m['text']!,
                              style: TextStyle(
                                  color: user ? Colors.white : navy,
                                  fontSize: 12,
                                  height: 1.5))));
                })),
        Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Row(children: [
              Expanded(
                  child: TextField(
                      controller: controller,
                      onSubmitted: (_) => send(),
                      decoration: InputDecoration(
                          hintText: 'Ask anything about your files...',
                          filled: true,
                          fillColor: pale,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(17),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 13)))),
              const SizedBox(width: 9),
              IconButton.filled(
                  onPressed: send,
                  style: IconButton.styleFrom(
                      backgroundColor: blue, foregroundColor: Colors.white),
                  icon: const Icon(Icons.arrow_upward_rounded)),
            ])),
      ]);
}

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});
  @override
  Widget build(BuildContext context) => PageBody(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading('Insights', 'A clearer view of your document activity.'),
        const SizedBox(height: 20),
        Row(children: const [
          Expanded(
              child: StatCard(
                  icon: Icons.description_rounded,
                  value: '24',
                  label: 'Pages reviewed',
                  tint: Color(0xFFEAF0FF),
                  color: blue)),
          SizedBox(width: 10),
          Expanded(
              child: StatCard(
                  icon: Icons.timer_rounded,
                  value: '3.8h',
                  label: 'Time saved',
                  tint: Color(0xFFE8F7F2),
                  color: Color(0xFF16A77A)))
        ]),
        sectionTitle('Document activity'),
        Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Documents analyzed',
                  style: TextStyle(
                      color: navy, fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 18),
              SizedBox(
                  height: 145,
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (i) {
                        final h = <double>[48, 75, 55, 105, 82, 125, 92][i];
                        return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                  width: 22,
                                  height: h,
                                  decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Color(0xFF79A0FF), blue]),
                                      borderRadius: BorderRadius.circular(8))),
                              const SizedBox(height: 8),
                              Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                                  style: const TextStyle(
                                      fontSize: 9, color: muted))
                            ]);
                      }))),
            ])),
        sectionTitle('Common document categories'),
        const CategoryBar(
            label: 'Contracts', value: .72, count: '8 files', color: blue),
        const CategoryBar(
            label: 'Financial reports',
            value: .48,
            count: '5 files',
            color: Color(0xFF16A77A)),
        const CategoryBar(
            label: 'Business documents',
            value: .31,
            count: '3 files',
            color: Color(0xFFE6A13B)),
      ]));
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
  @override
  Widget build(BuildContext context) => PageBody(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading(
            'Compare documents', 'Understand differences between two files.'),
        const SizedBox(height: 20),
        if (widget.docs.length < 2)
          const EmptyState(
              icon: Icons.compare_arrows_rounded,
              title: 'Add two documents',
              subtitle:
                  'You need at least two files in your library to compare them.')
        else ...[
          _selector('Document A', a, (v) => setState(() => a = v)),
          const SizedBox(height: 12),
          _selector('Document B', b, (v) => setState(() => b = v)),
          const SizedBox(height: 18),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF1C3476), Color(0xFF4778F4)]),
                  borderRadius: BorderRadius.circular(20)),
              child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.compare_arrows_rounded,
                        color: Colors.white, size: 28),
                    SizedBox(height: 12),
                    Text('Side-by-side intelligence',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 6),
                    Text(
                        'Compare key clauses, dates, amounts and obligations in one view.',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 11, height: 1.5))
                  ])),
          sectionTitle('Comparison preview'),
          const DetailLine(
              label: 'Structure',
              value: 'Both documents contain structured sections'),
          const DetailLine(
              label: 'Key terms', value: 'Differences require text extraction'),
          const DetailLine(
              label: 'Dates & amounts',
              value: 'No values extracted in demo mode'),
          const DetailLine(
              label: 'Status',
              value: 'Connect AI analysis to generate a real comparison'),
        ],
      ]));
  Widget _selector(String label, int value, ValueChanged<int> onChanged) =>
      Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    color: muted, fontSize: 10, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            DropdownButton<int>(
                value: value.clamp(0, widget.docs.length - 1).toInt(),
                isExpanded: true,
                underline: const SizedBox(),
                items: List.generate(
                    widget.docs.length,
                    (i) => DropdownMenuItem(
                        value: i,
                        child: Text(widget.docs[i].name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)))),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                })
          ]));
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
