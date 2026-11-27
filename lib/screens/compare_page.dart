import 'package:flutter/material.dart' hide Text;
import '../l10n/tr_text.dart';
import '../models/doc_item.dart';
import '../services/document_text_extractor.dart';
import '../services/openrouter_document_ai.dart';
import '../services/usage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

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
    if (!await UsageService.canUseDaily('ask')) {
      if (mounted) setState(() => error = UsageService.dailyLimitMessage);
      return;
    }
    await UsageService.recordDaily('ask');
    if (!mounted) return;
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
          Padding(padding: EdgeInsets.only(top: 9), child: Text('Choose two different files.',
            style: TextStyle(color: muted, fontSize: 13))),
        if (error != null) ...[
          const SizedBox(height: 14),
          Container(width: double.infinity, padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(13)),
            child: Text(error!, style: TextStyle(color: AppColors.dangerText, fontSize: 13, height: 1.5))),
        ],
        if (comparison != null) ...[
          const SizedBox(height: 20),
          _resultSection('Comparison summary', comparison!['summary']),
          _resultList('Similarities', comparison!['similarities']),
          _differenceList(comparison!['differences']),
          _resultList('Changed dates and amounts', comparison!['changed_dates_or_amounts']),
          _resultList('Points to review', comparison!['review_points']),
          const SizedBox(height: 10),
          Text('AI comparison is based on extracted text only. Check the original files before relying on any finding.',
            style: TextStyle(color: muted, fontSize: 12, height: 1.5)),
        ],
      ],
    ]),
  );

  Widget _selector(String label, int value, ValueChanged<int> onChanged) =>
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        DropdownButton<int>(
          value: value.clamp(0, widget.docs.length - 1).toInt(),
          isExpanded: true,
          underline: const SizedBox(),
          items: List.generate(widget.docs.length, (i) => DropdownMenuItem(
            value: i,
            child: Text(widget.docs[i].name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
          )),
          onChanged: busy ? null : (v) { if (v != null) onChanged(v); },
        ),
      ]),
    );

  Widget _resultSection(String title, dynamic value) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 13)),
      const SizedBox(height: 7),
      Text((value ?? 'No summary returned.').toString(), style: TextStyle(color: AppColors.bodyText, fontSize: 13, height: 1.55)),
    ]),
  );

  Widget _resultList(String title, dynamic values) {
    final items = values is List ? values : const [];
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.circle, color: blue, size: 7),
            const SizedBox(width: 8),
            Expanded(child: Text(item.toString(), style: TextStyle(color: AppColors.bodyText, fontSize: 13, height: 1.5))),
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
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Differences', style: TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 8),
        ...items.map((entry) {
          final item = entry is Map ? entry : <String, dynamic>{'topic': entry.toString()};
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: pale, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((item['topic'] ?? 'Difference').toString(), style: TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 6),
              Text('A · ${item['document_a'] ?? 'Not found'}', style: TextStyle(color: AppColors.bodyText, fontSize: 12, height: 1.5)),
              Text('B · ${item['document_b'] ?? 'Not found'}', style: TextStyle(color: AppColors.bodyText, fontSize: 12, height: 1.5)),
              if (item['significance'] != null) ...[
                const SizedBox(height: 5),
                Text('Why it matters: ${item['significance']}', style: TextStyle(color: navy, fontSize: 12, height: 1.5, fontWeight: FontWeight.w600)),
              ],
            ]),
          );
        }),
      ]),
    );
  }
}
