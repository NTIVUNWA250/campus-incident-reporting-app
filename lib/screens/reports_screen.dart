import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/incident.dart';
import '../state/incident_controller.dart';
import '../widgets/common.dart';
import '../widgets/report_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    _search.text = context.read<IncidentController>().query;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<IncidentController>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionTitle(reports.staff ? 'Campus reports' : 'My reports'),
        const SizedBox(height: 6),
        Text(
          reports.staff
              ? 'Review issues and keep students informed.'
              : 'Every report is a step toward a better campus.',
          style: const TextStyle(color: muted),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: 'Search title, description or location',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Clear filters',
              icon: const Icon(Icons.clear),
              onPressed: () {
                _search.clear();
                reports.filters(reset: true);
              },
            ),
          ),
          onChanged: (v) => reports.filters(
            search: v,
            category: reports.category,
            status: reports.status,
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<IncidentCategory?>(
          initialValue: reports.category,
          key: ValueKey(reports.category),
          decoration: const InputDecoration(
            labelText: 'Category',
            prefixIcon: Icon(Icons.tune),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('All categories')),
            ...IncidentCategory.values.map(
              (c) => DropdownMenuItem(value: c, child: Text(c.label)),
            ),
          ],
          onChanged: (v) =>
              reports.filters(category: v, status: reports.status),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: reports.status == null,
                  onSelected: (_) =>
                      reports.filters(category: reports.category),
                ),
              ),
              ...IncidentStatus.values.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s.label),
                    selected: reports.status == s,
                    onSelected: (_) =>
                        reports.filters(category: reports.category, status: s),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
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
        else if (reports.filtered.isEmpty)
          const EmptyState(
            title: 'No matching reports',
            message:
                'Try another search or category, clear filters, or submit your first incident.',
          )
        else
          ...reports.filtered.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ReportCard(i),
            ),
          ),
        Text(
          'Searching ${reports.incidents.length} loaded reports, newest first.',
          style: const TextStyle(fontSize: 12, color: muted),
        ),
        if (reports.canLoadMore)
          TextButton(
            onPressed: () => reports.reload(more: true),
            child: const Text('Load older reports'),
          ),
      ],
    );
  }
}
