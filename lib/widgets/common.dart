import 'package:flutter/material.dart' hide Text;
import '../l10n/tr_text.dart';
import '../models/doc_item.dart';
import '../theme/app_theme.dart';

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
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: navy,
                  letterSpacing: -0.8)),
          const SizedBox(height: 5),
          Text(subtitle, style: TextStyle(fontSize: 13, color: muted)),
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
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: navy))),
        if (action != null)
          TextButton(
              onPressed: onTap,
              child: Text(action,
                  style: TextStyle(
                      color: blue, fontWeight: FontWeight.w700))),
      ]),
    );

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
          color: AppColors.surface, borderRadius: BorderRadius.circular(19)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: tint, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 17)),
        const SizedBox(height: 10),
        Text(value,
            style: TextStyle(
                fontSize: 21, fontWeight: FontWeight.w800, color: navy)),
        Text(label, style: TextStyle(fontSize: 12, color: muted)),
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
              color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: blue, size: 22),
                const SizedBox(height: 9),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: navy)),
                const SizedBox(height: 3),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: muted)),
              ])));
}

class DocumentTile extends StatelessWidget {
  final DocItem doc;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const DocumentTile(
      {super.key, required this.doc, this.onTap, this.onLongPress});
  @override
  Widget build(BuildContext context) {
    final color =
        doc.type == 'PDF' ? const Color(0xFFE65E68) : const Color(0xFF4778E8);
    return Card(
        margin: const EdgeInsets.only(bottom: 9),
        child: ListTile(
          onTap: onTap,
          onLongPress: onLongPress,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
          leading: Container(
              width: 43,
              height: 47,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insert_drive_file_rounded,
                        color: color, size: 20),
                    Text(doc.type,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: color))
                  ])),
          title: Text(doc.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: navy)),
          subtitle: Text('${doc.size}  ·  ${doc.date}',
              style: TextStyle(fontSize: 12, color: muted)),
          trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                  color: doc.status == 'Analyzed'
                      ? AppColors.successSoft
                      : AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(doc.status,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: doc.status == 'Analyzed'
                          ? AppColors.success
                          : AppColors.warning))),
        ));
  }
}

class MiniMetric extends StatelessWidget {
  final String value, label;
  const MiniMetric({super.key, required this.value, required this.label});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: TextStyle(
                color: blue, fontSize: 19, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: muted, fontSize: 11))
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
                style: TextStyle(color: muted, fontSize: 13))),
        Expanded(
            child: Text(value,
                style: TextStyle(
                    color: navy, fontWeight: FontWeight.w600, fontSize: 13)))
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
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(13)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(level.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                letterSpacing: .8,
                fontWeight: FontWeight.w900,
                color: color)),
        const SizedBox(height: 5),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14, color: navy)),
        const SizedBox(height: 4),
        Text(detail,
            style: TextStyle(fontSize: 12, color: muted, height: 1.45))
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
                  style: TextStyle(
                      color: navy, fontWeight: FontWeight.w700, fontSize: 13))),
          Text(count, style: TextStyle(color: muted, fontSize: 12))
        ]),
        const SizedBox(height: 8),
        ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.surface,
                color: color))
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
              style: TextStyle(
                  color: navy, fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Text(subtitle,
              style: TextStyle(color: muted, fontSize: 12)),
          trailing: Text(trailing ?? '›',
              style: TextStyle(color: muted, fontSize: 16))));
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
          color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Icon(icon, size: 36, color: blue),
        const SizedBox(height: 12),
        Text(title,
            style: TextStyle(
                color: navy, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 6),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 13, height: 1.5))
      ]));
}
