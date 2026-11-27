import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/doc_item.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/rename_dialog.dart';

/// Whether a document matches the search text: its name, or anything in its
/// saved analysis (summary, details, risks, dates, amounts).
bool matchesQuery(DocItem doc, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (doc.name.toLowerCase().contains(q)) return true;
  final json = doc.analysisJson;
  if (json == null) return false;
  try {
    return _textValues(jsonDecode(json)).any((t) => t.toLowerCase().contains(q));
  } catch (_) {
    return false;
  }
}

/// Every text value inside decoded JSON (not the key names).
Iterable<String> _textValues(Object? node) sync* {
  if (node is String) {
    yield node;
  } else if (node is Map) {
    for (final v in node.values) {
      yield* _textValues(v);
    }
  } else if (node is List) {
    for (final v in node) {
      yield* _textValues(v);
    }
  }
}

class LibraryPage extends StatefulWidget {
  final List<DocItem> docs;
  final VoidCallback onUpload;
  final ValueChanged<DocItem> onOpen;
  final ValueChanged<DocItem> onDelete;
  final void Function(DocItem doc, String newName) onRename;
  const LibraryPage(
      {super.key,
      required this.docs,
      required this.onUpload,
      required this.onOpen,
      required this.onDelete,
      required this.onRename});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String query = '';
  String filter = 'All';

  Future<void> _rename(DocItem doc) async {
    final name = await showRenameDialog(context, doc.name);
    if (name != null && name != doc.name) widget.onRename(doc, name);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.docs
        .where((d) =>
            matchesQuery(d, query) &&
            (filter == 'All' || d.type == filter))
        .toList();
    return PageBody(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading(
          'Document library', '${widget.docs.length} files in your workspace',
          trailing: IconButton(
              onPressed: widget.onUpload,
              icon: Icon(Icons.add_circle, color: blue, size: 30))),
      const SizedBox(height: 20),
      TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: InputDecoration(
              hintText: 'Search names and analyses...',
              prefixIcon: Icon(Icons.search_rounded, color: muted),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14))),
      const SizedBox(height: 13),
      Wrap(
          spacing: 8,
          children: ['All', 'PDF', 'DOCX', 'TXT', 'RTF', 'SCAN']
              .map((f) => ChoiceChip(
                  label: Text(f),
                  selected: filter == f,
                  onSelected: (_) => setState(() => filter = f),
                  selectedColor: AppColors.accentSoft,
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
      if (items.isNotEmpty)
        Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Tap to analyze · hold to rename · swipe to delete',
                style: TextStyle(color: muted, fontSize: 13))),
      ...items.map((d) => Dismissible(
            key: ObjectKey(d),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => widget.onDelete(d),
            background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 22),
                margin: const EdgeInsets.only(bottom: 9),
                decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white)),
            child: DocumentTile(
                doc: d,
                onTap: () => widget.onOpen(d),
                onLongPress: () => _rename(d)),
          )),
    ]));
  }
}
