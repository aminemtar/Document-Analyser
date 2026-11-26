import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/doc_item.dart';
import '../services/document_text_extractor.dart';
import '../services/openrouter_document_ai.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

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
