import 'package:flutter/material.dart' hide Text;
import '../l10n/tr_text.dart';
import '../models/doc_item.dart';
import '../theme/app_theme.dart';
import '../widgets/attention_card.dart';
import '../widgets/common.dart';

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

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
        heading('${_greeting()} 👋', 'Your documents, understood in seconds.'),
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
                  color: blue.withValues(alpha: .18),
                  blurRadius: 25,
                  offset: const Offset(0, 12))
            ],
          ),
          child: Stack(children: [
            Positioned(
                right: -15,
                top: -25,
                child: Icon(Icons.auto_awesome_rounded,
                    size: 150, color: Colors.white.withValues(alpha: .08))),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(30)),
                  child: const Text('YOUR AI DOCUMENT WORKSPACE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
                      color: Colors.white.withValues(alpha: .78),
                      fontSize: 14,
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
                  tint: AppColors.surfaceTint,
                  color: blue)),
          const SizedBox(width: 10),
              Expanded(
              child: StatCard(
                  icon: Icons.check_circle_rounded,
                  value: '${docs.where((d) => d.analysisJson != null).length}',
                  label: 'Analyzed',
                  tint: AppColors.surfaceTint,
                  color: blue)),
        ]),
        AttentionCard(docs: docs, onOpen: onOpen),
        sectionTitle('Recent documents',
            action: 'View all', onTap: () => onNavigate(1)),
        if (docs.isEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Your imported files will appear here.',
              style: TextStyle(color: muted, fontSize: 13)),
          )
        else
          ...docs.take(3).map((d) =>
              DocumentTile(doc: d, onTap: () => onOpen(d))),
        sectionTitle('Explore your workspace'),
        // Rows sized by their content (not a fixed aspect ratio), so tiles
        // grow with long subtitles, small screens and large text settings.
        _tileRow(
            ActionTile(
                icon: Icons.auto_awesome,
                title: 'Ask your documents',
                subtitle: 'Get instant answers',
                onTap: () => onNavigate(3)),
            ActionTile(
                icon: Icons.compare_arrows_rounded,
                title: 'Compare files',
                subtitle: 'Find what changed',
                onTap: () => onNavigate(5))),
        const SizedBox(height: 11),
        _tileRow(
            ActionTile(
                icon: Icons.insights_rounded,
                title: 'Insights',
                subtitle: 'See key patterns',
                onTap: () => onNavigate(4)),
            ActionTile(
                icon: Icons.shield_outlined,
                title: 'Risk review',
                subtitle: 'Spot key clauses',
                onTap: () => onNavigate(2))),
      ]));

  /// Two tiles side by side. Tile text is single-line, so both tiles always
  /// have the same height without measuring them (IntrinsicHeight
  /// under-measured wrapped text and overflowed).
  Widget _tileRow(Widget left, Widget right) => Row(children: [
        Expanded(child: left),
        const SizedBox(width: 11),
        Expanded(child: right),
      ]);
}
