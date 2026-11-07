import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/firebase_config.dart';
import '../state/session_controller.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionTitle('My profile'),
        const SizedBox(height: 28),
        const CircleAvatar(
          radius: 44,
          backgroundColor: Color(0xFFEDE6FF),
          child: Icon(Icons.person_outline, size: 44, color: brand),
        ),
        const SizedBox(height: 18),
        Text(
          session.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          session.user?.email ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted),
        ),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.verified_user_outlined, color: brand),
                title: const Text('Verified ALU account'),
                subtitle: Text(
                  session.isStaff ? 'Authorized campus staff' : 'Student',
                ),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.lock_outline, color: brand),
                title: Text('Your privacy'),
                subtitle: Text(
                  'Only you and authorized campus staff can access your reports and photos. Avoid sharing passwords or sensitive personal information in reports.',
                ),
              ),
              if (useEmulators)
                const ListTile(
                  leading: Icon(Icons.computer, color: brand),
                  title: Text('Local Firebase emulators'),
                  subtitle: Text(
                    'Development data stays on this computer. No billing account is connected.',
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: session.busy
              ? null
              : () => performAction(context, session.refresh),
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh account permissions'),
        ),
        const SizedBox(height: 12),
        BusyButton(
          label: 'Sign out',
          busy: session.busy,
          onPressed: () => performAction(context, session.signOut),
        ),
        const SizedBox(height: 24),
        const Text(
          'Campus Care\nA better campus, together.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, height: 1.6),
        ),
      ],
    );
  }
}
