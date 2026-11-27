import 'dart:convert';
import 'package:flutter/material.dart' hide Text;
import '../l10n/tr_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/doc_item.dart';
import '../services/document_text_extractor.dart';
import '../services/openrouter_document_ai.dart';
import '../services/usage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_offers.dart';
import '../widgets/common.dart';

class AssistantPage extends StatefulWidget {
  final List<DocItem> docs;

  /// A question handed over from another screen; it is sent once on open.
  final String? pendingQuestion;
  final VoidCallback? onPendingConsumed;
  const AssistantPage(
      {super.key,
      required this.docs,
      this.pendingQuestion,
      this.onPendingConsumed});
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

  static const _historyKey = 'assistant_messages';
  static const _welcome =
      'Ask a question about your uploaded files. I’ll use their extracted text and name the source when possible.';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  /// The page is rebuilt whenever the user switches tabs, so the conversation
  /// is kept on the device and restored here.
  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_historyKey);
    if (saved != null) {
      try {
        final restored = (jsonDecode(saved) as List)
            .map((e) => Map<String, String>.from(e as Map))
            .toList();
        if (restored.isNotEmpty) {
          messages
            ..clear()
            ..addAll(restored);
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {});
    final pending = widget.pendingQuestion;
    if (pending != null) {
      widget.onPendingConsumed?.call();
      controller.text = pending;
      send();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keep =
        messages.length > 60 ? messages.sublist(messages.length - 60) : messages;
    await prefs.setString(_historyKey, jsonEncode(keep));
  }

  Future<void> _clearChat() async {
    setState(() {
      messages
        ..clear()
        ..add({'role': 'ai', 'text': _welcome});
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> send() async {
    final question = controller.text.trim();
    if (question.isEmpty || busy) return;
    if (widget.docs.isEmpty) {
      setState(() {
        messages.add({'role': 'user', 'text': question});
        messages.add({'role': 'ai', 'text': 'Upload a PDF, DOCX, TXT or RTF file first. I need real document content to answer questions.'});
        controller.clear();
      });
      _saveHistory();
      return;
    }
    if (!await UsageService.canUseDaily('ask')) {
      if (!mounted) return;
      // Out of daily questions: offer more for a short ad before refusing.
      if (!await offerQuestionBonus(context)) {
        if (mounted) setState(() => error = UsageService.dailyLimitMessage);
        return;
      }
    }
    await UsageService.recordDaily('ask');
    if (!mounted) return;
    setState(() {
      messages.add({'role': 'user', 'text': question});
      controller.clear();
      busy = true;
      error = null;
    });
    Map<String, String>? reply;
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
      // The answer appears as it is written. It is added to the list even if
      // the user leaves the tab meanwhile, so it is saved either way.
      messages.add({'role': 'ai', 'text': ''});
      reply = messages.last;
      final buffer = StringBuffer();
      await for (final piece in OpenRouterDocumentAI.askStream(
        question: question,
        documents: available,
      )) {
        buffer.write(piece);
        reply['text'] = buffer.toString();
        if (mounted) setState(() {});
      }
      if (buffer.isEmpty) {
        throw Exception('The AI service returned an empty response.');
      }
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      final failure = 'I couldn’t complete that request. ${error!}';
      if (reply != null && (reply['text'] ?? '').isEmpty) {
        reply['text'] = failure;
      } else if (reply != null) {
        reply['text'] = '${reply['text']}\n\n(The answer was cut off: ${error!})';
      } else {
        messages.add({'role': 'ai', 'text': failure});
      }
    } finally {
      busy = false;
      if (mounted) setState(() {});
      _saveHistory();
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
        heading('AI assistant', 'Ask questions across your uploaded documents.',
            trailing: IconButton(
                tooltip: 'Clear conversation'.tr,
                onPressed: busy ? null : _clearChat,
                icon: Icon(Icons.delete_sweep_outlined, color: muted))),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.folder_copy_outlined, color: blue, size: 16),
          const SizedBox(width: 7),
          Text('${widget.docs.length} real file(s) available',
            style: TextStyle(color: muted, fontSize: 13)),
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
            alignment: user
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 330),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: user ? blue : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(m['text']!,
                style: TextStyle(color: user ? Colors.white : navy, fontSize: 14, height: 1.5)),
            ),
          );
        },
      ),
    ),
    if (busy) LinearProgressIndicator(color: blue, backgroundColor: pale),
    Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Row(children: [
        Expanded(child: TextField(
          controller: controller,
          enabled: !busy,
          onSubmitted: (_) => send(),
          decoration: InputDecoration(
            hintText: 'Ask about your uploaded files…'.tr,
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
