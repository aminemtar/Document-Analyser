import 'package:flutter/material.dart';
import '../models/doc_item.dart';
import '../theme/app_theme.dart';
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
        if (docs.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Your imported files will appear here.',
              style: TextStyle(color: muted, fontSize: 11)),
          )
        else
          ...docs.take(3).map((d) =>
              DocumentTile(doc: d, onTap: () => onOpen(d))),
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
