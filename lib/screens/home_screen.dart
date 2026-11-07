import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/incident.dart';
import '../state/incident_controller.dart';
import '../state/session_controller.dart';
import '../widgets/common.dart';
import '../widgets/report_card.dart';
import 'incident_form_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: switch (_index) {
        1 => const ReportsScreen(),
        3 => const ProfileScreen(),
        _ => HomeScreen(onSeeAll: () => setState(() => _index = 1)),
      },
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (value) {
        if (value == 2) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const IncidentFormScreen()),
          );
        } else {
          setState(() => _index = value);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: 'Reports',
        ),
        NavigationDestination(
          icon: CircleAvatar(
            backgroundColor: brand,
            child: Icon(Icons.add, color: Colors.white),
          ),
          label: 'Report',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.onSeeAll, super.key});
  final VoidCallback onSeeAll;
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final reports = context.watch<IncidentController>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${session.name.split(' ').first}',
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session.isStaff
                        ? 'Your campus, working better.'
                        : 'Help make your campus safer.',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFFEDE6FF),
              child: Icon(Icons.school_outlined, color: brand),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Report issues and track their resolution.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6632EF), Color(0xFFA18BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: brand.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'See an issue\non campus?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.account_balance_outlined,
                    size: 70,
                    color: Color(0xFFDDD3FF),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Small reports. Meaningful change.\nHelp improve our learning environment.',
                style: TextStyle(color: Colors.white, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: brand,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const IncidentFormScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Report an issue'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionTitle('Report summary', action: 'See all', onTap: onSeeAll),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth < 340 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3
                ? 2
                : 4;
            final stats = [
              (
                'Reports',
                reports.incidents.length,
                Icons.description_outlined,
                const Color(0xFFF0EBFF),
                brand,
              ),
              (
                'In progress',
                reports.incidents
                    .where((i) => i.status == IncidentStatus.inProgress)
                    .length,
                Icons.schedule,
                const Color(0xFFE9F3FF),
                const Color(0xFF286BDF),
              ),
              (
                'Resolved',
                reports.incidents
                    .where((i) => i.status == IncidentStatus.resolved)
                    .length,
                Icons.check_circle_outline,
                const Color(0xFFE6F8F1),
                const Color(0xFF298359),
              ),
              (
                'Submitted',
                reports.incidents
                    .where((i) => i.status == IncidentStatus.submitted)
                    .length,
                Icons.error_outline,
                const Color(0xFFFFEDF2),
                const Color(0xFFD44565),
              ),
            ];
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stats
                  .map(
                    (s) => SizedBox(
                      width:
                          (constraints.maxWidth - (columns - 1) * 8) / columns,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: s.$4,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Icon(s.$3, color: s.$5, size: 28),
                            const SizedBox(height: 12),
                            Text(
                              '${s.$2}',
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              s.$1,
                              style: const TextStyle(fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Summary of ${session.isStaff ? 'campus' : 'your'} loaded reports.',
          style: const TextStyle(fontSize: 11, color: muted),
        ),
        const SizedBox(height: 20),
        SectionTitle('Recent reports', action: 'See all', onTap: onSeeAll),
        const SizedBox(height: 12),
        if (reports.loading)
          const Center(child: CircularProgressIndicator())
        else if (reports.error != null)
          EmptyState(
            title: 'Could not load reports',
            message: reports.error!,
            action: TextButton(
              onPressed: reports.reload,
              child: const Text('Retry'),
            ),
          )
        else if (reports.incidents.isEmpty)
          const EmptyState(
            title: 'A fresh start',
            message:
                'Your first report can make a difference. Use Report to tell us what needs attention.',
          )
        else
          ...reports.incidents
              .take(5)
              .map(
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ReportCard(i),
                ),
              ),
        const SizedBox(height: 12),
        const Text(
          'For urgent danger, contact campus security directly. This app is not an emergency service.',
          style: TextStyle(fontSize: 12, color: muted, height: 1.5),
        ),
      ],
    );
  }
}
