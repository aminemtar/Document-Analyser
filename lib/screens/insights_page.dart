import 'package:flutter/material.dart';
import '../models/doc_item.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

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
