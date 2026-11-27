import 'dart:convert';
import 'package:flutter/material.dart' hide Text;
import '../l10n/tr_text.dart';
import 'package:flutter/services.dart';
import '../models/doc_item.dart';
import '../services/document_text_extractor.dart';
import '../services/openrouter_document_ai.dart';
import '../services/usage_service.dart';
import '../services/ad_service.dart';
import '../services/export_service.dart';
import 'paywall_page.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AnalysisPage extends StatefulWidget {
  final List<DocItem> docs;
  final String? selectedPath;
  final ValueChanged<String?> onSelectPath;
  final ValueChanged<DocItem> onUpdate;

  /// When true, opening the page on a document that has no saved analysis
  /// starts the analysis straight away (set when a document is tapped).
  final bool autoRun;

  /// Opens the assistant with a ready-made question about this document.
  final ValueChanged<String>? onAsk;
  const AnalysisPage({
    super.key,
    required this.docs,
    required this.selectedPath,
    required this.onSelectPath,
    required this.onUpdate,
    this.autoRun = false,
    this.onAsk,
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
    if (widget.autoRun && widget.docs.isNotEmpty) {
      final doc = widget.docs[selectedIndex.clamp(0, widget.docs.length - 1)];
      if (doc.analysisJson == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !busy) _analyze(doc);
        });
      }
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
    if (!await UsageService.canAnalyze()) {
      if (!mounted) return;
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PaywallPage()));
      return;
    }
    if (!mounted) return;
    setState(() { busy = true; error = null; result = null; });
    try {
      final text = await DocumentTextExtractor.extract(doc.path!, doc.type);
      if (text.trim().length < 40) {
        throw Exception('No readable text was found, even after trying to read the pages as images. Try a clearer scan or a text-based file. Arabic text in scans cannot be recognized yet.');
      }
      final analysis = await OpenRouterDocumentAI.analyze(
        fileName: doc.name, fileType: doc.type, text: text);
      final encoded = jsonEncode(analysis);
      final updated = doc.copyWith(status: 'Analyzed', analysisJson: encoded);
      widget.onUpdate(updated);
      await UsageService.recordAnalysis();
      AdService.onAnalysisCompleted();
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
    final tabs = ['Overview', 'Key details', 'Risks', 'Dates', 'Actions'];
    return PageBody(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading('Document analysis', 'Extract facts, understand obligations and identify risks.'),
      const SizedBox(height: 18),
      if (doc == null)
        const EmptyState(icon: Icons.document_scanner_rounded, title: 'Add a document to begin',
          subtitle: 'Upload a PDF, DOCX, TXT or RTF file. The analysis will be generated from its actual text.')
      else ...[
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.description_rounded, color: blue, size: 25),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(doc.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, color: navy, fontSize: 14)),
                Text('${doc.size} · ${doc.type} · ${doc.status}',
                  style: TextStyle(color: muted, fontSize: 12))
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
            if (busy) Padding(padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(color: blue, backgroundColor: pale)),
          ]),
        ),
        if (error != null) ...[
          const SizedBox(height: 14),
          Container(width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(14)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFD64D5A), size: 19),
              const SizedBox(width: 9), Expanded(child: Text(error!,
                style: TextStyle(color: AppColors.dangerText, fontSize: 13, height: 1.5)))
            ]))
        ],
        if (data != null) ...[
          const SizedBox(height: 18),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.verified_rounded, color: blue, size: 18),
                const SizedBox(width: 7),
                Expanded(child: Text('Analysis generated from document text',
                  style: TextStyle(color: navy, fontSize: 14, fontWeight: FontWeight.w800))),
                IconButton(
                  tooltip: 'Share analysis'.tr,
                  onPressed: () => _shareSummary(doc, data),
                  icon: Icon(Icons.ios_share_rounded, color: blue, size: 20)),
                IconButton(
                  tooltip: 'Copy summary'.tr,
                  onPressed: () => _copySummary(doc, data),
                  icon: Icon(Icons.copy_rounded, color: blue, size: 20)),
              ]),
              const SizedBox(height: 8),
              _countsRow(data),
              const SizedBox(height: 13),
              Wrap(spacing: 5, children: List.generate(tabs.length, (i) => ChoiceChip(
                label: Text(tabs[i]), selected: tab == i, onSelected: (_) => setState(() => tab = i),
                selectedColor: AppColors.accentSoft,
                labelStyle: TextStyle(fontSize: 12, color: tab == i ? blue : muted, fontWeight: FontWeight.w700)))),
              const SizedBox(height: 16),
              if (tab == 0) ...[
                _reviewGauge(data['review_level']),
                Text((data['document_type'] ?? 'Document').toString().toUpperCase(),
                  style: TextStyle(color: blue, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: .8)),
                const SizedBox(height: 8),
                Text('Executive summary', style: TextStyle(fontWeight: FontWeight.w800, color: navy, fontSize: 15)),
                const SizedBox(height: 7),
                Text((data['summary'] ?? 'No summary returned.').toString(),
                  style: TextStyle(color: AppColors.bodyText, height: 1.6, fontSize: 14)),
                if (data['confidence_notes'] != null) ...[
                  const SizedBox(height: 12),
                  Text('Review note: ${data['confidence_notes']}',
                    style: TextStyle(color: muted, fontSize: 12, height: 1.5))
                ],
                if (_listOf(data['suggested_questions']).isNotEmpty && widget.onAsk != null) ...[
                  const SizedBox(height: 18),
                  Text('Ask about this document', style: TextStyle(fontWeight: FontWeight.w800, color: navy, fontSize: 15)),
                  const SizedBox(height: 8),
                  ..._listOf(data['suggested_questions']).take(3).map((q) => _questionTile(doc, q.toString())),
                ]
              ] else if (tab == 1) ...[
                _stringList(data['key_details'], empty: 'No key details were identified.')
              ] else if (tab == 2) ...[
                _riskList(data['risks'])
              ] else if (tab == 3) ...[
                _datesView(data)
              ] else ...[
                _stringList(data['action_items'], empty: 'No action items were identified.')
              ]
            ]))
        ] else if (!busy && error == null) ...[
          const SizedBox(height: 16),
          Text('Your analysis will appear here after you run the document through the AI model.',
            style: TextStyle(color: muted, fontSize: 13, height: 1.5))
        ],
        const SizedBox(height: 14),
        Text('AI-generated analysis can miss context or misinterpret clauses. Verify important facts and seek professional advice for legal, financial or medical decisions.',
          style: TextStyle(color: muted, fontSize: 12, height: 1.5))
      ]
    ]));
  }

  List _listOf(dynamic value) => value is List ? value : const [];

  Widget _reviewGauge(dynamic raw) {
    final num? parsed = raw is num ? raw : num.tryParse('$raw');
    if (parsed == null) return const SizedBox.shrink();
    final score = parsed.round().clamp(0, 100).toInt();
    final color = score < 34
        ? AppColors.success
        : score < 67
            ? AppColors.warning
            : AppColors.danger;
    final label = score < 34
        ? 'Low attention needed'
        : score < 67
            ? 'Worth a careful read'
            : 'Needs close review';
    return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          SizedBox(
              width: 56,
              height: 56,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                    child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 6,
                        color: color,
                        backgroundColor: color.withValues(alpha: .15))),
                Text('$score',
                    style: TextStyle(
                        color: color, fontSize: 16, fontWeight: FontWeight.w800)),
              ])),
          const SizedBox(width: 12),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    color: navy, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(
                'Based on the risks found in the text. It is a reading aid, not a verdict.',
                style: TextStyle(color: muted, fontSize: 12, height: 1.4)),
          ])),
        ]));
  }

  Widget _questionTile(DocItem doc, String question) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => widget.onAsk?.call('About "${doc.name}": $question'),
          child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: pale, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    color: blue, size: 17),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(question,
                        style: TextStyle(
                            color: navy, fontSize: 13, height: 1.4))),
                Icon(Icons.arrow_forward_rounded, color: muted, size: 16),
              ]))));

  Widget _datesView(Map<String, dynamic> data) {
    final dates = _listOf(data['important_dates']);
    final amounts = _listOf(data['amounts']);
    if (dates.isEmpty && amounts.isEmpty) {
      return Text('No dates or amounts were found in the text.',
          style: TextStyle(color: muted, fontSize: 13, height: 1.5));
    }
    String str(dynamic v) => v == null ? '' : v.toString().trim();
    Widget row(IconData icon, String title, String value, String note) =>
        Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: pale, borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: blue, size: 18),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(
                        color: navy, fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        color: blue, fontSize: 13, fontWeight: FontWeight.w700)),
                if (note.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(note,
                          style: TextStyle(
                              color: muted, fontSize: 12, height: 1.4))),
              ])),
            ]));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...dates.map((d) {
        final m = d is Map ? d : <String, dynamic>{'label': d.toString()};
        final date = str(m['date']);
        final label = str(m['label']);
        return row(
            Icons.event_rounded,
            label.isEmpty ? 'Date' : label,
            date.isEmpty || date == 'null' ? 'Date not specified' : date,
            str(m['note']));
      }),
      ...amounts.map((a) {
        final m = a is Map ? a : <String, dynamic>{'label': a.toString()};
        final label = str(m['label']);
        return row(Icons.payments_outlined, label.isEmpty ? 'Amount' : label,
            str(m['value']), '');
      }),
    ]);
  }

  Widget _countsRow(Map<String, dynamic> data) {
    final risks = _listOf(data['risks']);
    final highRisks = risks
        .where((r) =>
            r is Map && (r['level'] ?? '').toString().toLowerCase().contains('high'))
        .length;
    Widget chip(String value, String label, Color color) => Expanded(
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 18, fontWeight: FontWeight.w800)),
              Text(label, style: TextStyle(color: muted, fontSize: 12)),
            ])));
    return Row(children: [
      chip('${_listOf(data['key_details']).length}', 'Details', blue),
      const SizedBox(width: 8),
      chip('${risks.length}', highRisks > 0 ? '$highRisks high risk' : 'Risks',
          highRisks > 0 ? AppColors.danger : blue),
      const SizedBox(width: 8),
      chip('${_listOf(data['action_items']).length}', 'Actions', blue),
    ]);
  }

  Future<void> _copySummary(DocItem doc, Map<String, dynamic> data) async {
    await Clipboard.setData(
        ClipboardData(text: analysisToText(doc.name, data)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Summary copied'), behavior: SnackBarBehavior.floating));
  }

  Future<void> _shareSummary(DocItem doc, Map<String, dynamic> data) async {
    try {
      await ExportService.shareAnalysis(doc.name, data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sharing is not available on this device.'),
          behavior: SnackBarBehavior.floating));
    }
  }

  Widget _stringList(dynamic values, {required String empty}) {
    final items = values is List ? values : const [];
    if (items.isEmpty) return Text(empty, style: TextStyle(color: muted, fontSize: 13));
    return Column(children: items.map((v) => Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: pale, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.check_circle_outline_rounded, color: blue, size: 16),
        const SizedBox(width: 8), Expanded(child: Text(v.toString(),
          style: TextStyle(color: navy, fontSize: 13, height: 1.5)))
      ])
    )).toList());
  }

  Widget _riskList(dynamic values) {
    final items = values is List ? values : const [];
    if (items.isEmpty) {
      return Text('No risks were identified by the model. This is not a guarantee that the document is risk-free.',
          style: TextStyle(color: muted, fontSize: 13, height: 1.5));
    }
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
