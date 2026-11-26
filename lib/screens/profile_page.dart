import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => PageBody(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading('Your profile', 'Manage your workspace preferences.'),
        const SizedBox(height: 22),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(22)),
            child: const Column(children: [
              CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFFE7EDFF),
                  child: Text('M',
                      style: TextStyle(
                          color: blue,
                          fontSize: 27,
                          fontWeight: FontWeight.w800))),
              SizedBox(height: 12),
              Text('My workspace',
                  style: TextStyle(
                      color: navy, fontWeight: FontWeight.w800, fontSize: 17)),
              SizedBox(height: 4),
              Text('Free plan · Personal account',
                  style: TextStyle(color: muted, fontSize: 11)),
            ])),
        sectionTitle('Preferences'),
        const SettingsRow(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: 'English',
            trailing: 'EN'),
        const SettingsRow(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Manage alerts'),
        const SettingsRow(
            icon: Icons.lock_outline_rounded,
            title: 'Privacy & security',
            subtitle: 'Your files stay in your workspace'),
        const SettingsRow(
            icon: Icons.help_outline_rounded,
            title: 'Help & support',
            subtitle: 'Get assistance'),
        const SizedBox(height: 18),
        const Center(
            child: Text('DocuMind AI  ·  Version 1.0.0',
                style: TextStyle(color: muted, fontSize: 10))),
      ]));
}
