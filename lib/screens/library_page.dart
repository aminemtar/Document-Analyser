import 'package:flutter/material.dart';
import '../models/doc_item.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/rename_dialog.dart';

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
          children: ['All', 'PDF', 'DOCX', 'TXT', 'RTF']
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
      if (items.isNotEmpty)
        const Padding(
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
