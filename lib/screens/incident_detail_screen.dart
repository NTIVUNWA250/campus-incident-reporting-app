import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/validation.dart';
import '../models/incident.dart';
import '../state/incident_controller.dart';
import '../state/session_controller.dart';
import '../widgets/common.dart';
import '../widgets/report_card.dart';
import 'incident_form_screen.dart';

class IncidentDetailScreen extends StatefulWidget {
  const IncidentDetailScreen(this.id, {super.key});
  final String id;
  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  bool _busy = false;
  Future<void> _advance(Incident incident) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _StatusDialog(incident.status.next!),
    );
    if (note == null || !mounted) return;
    setState(() => _busy = true);
    await performAction(
      context,
      () => context.read<IncidentController>().repository.advance(
        incident,
        context.read<SessionController>().user!.uid,
        note,
      ),
      success: 'Status updated.',
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _delete(Incident incident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this report?'),
        content: const Text(
          'The report and attached photo will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep report'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final ok = await performAction(
      context,
      () => context.read<IncidentController>().repository.delete(incident),
      success: 'Report deleted.',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<IncidentController>();
    final session = context.watch<SessionController>();
    final matches = reports.incidents.where((i) => i.id == widget.id);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incident details')),
        body: const EmptyState(
          title: 'Report unavailable',
          message: 'This report may have been deleted. Return to your reports.',
        ),
      );
    }
    final incident = matches.first;
    final editable =
        incident.ownerId == session.user?.uid &&
        incident.status == IncidentStatus.submitted;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Incident details'),
          actions: [
            if (editable)
              PopupMenuButton<String>(
                enabled: !_busy,
                onSelected: (action) {
                  if (action == 'delete') {
                    _delete(incident);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => IncidentFormScreen(incident: incident),
                      ),
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit report'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete report'),
                  ),
                ],
              ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0ECFF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              categoryIcon(incident.category.name),
                              color: brand,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  incident.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  incident.location,
                                  style: const TextStyle(color: muted),
                                ),
                                const SizedBox(height: 10),
                                StatusBadge(incident.status),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Submitted on ${dateLabel(incident.createdAt)}',
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reported by ${incident.reporterName}',
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Category: ${incident.category.label}',
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionTitle('Status timeline'),
              const SizedBox(height: 16),
              ...IncidentStatus.values.map((status) {
                final events = incident.history.where(
                  (e) => e.status == status,
                );
                final event = events.isEmpty ? null : events.first;
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Icon(
                            event != null
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: event != null
                                ? brand
                                : const Color(0xFFCDD0E1),
                          ),
                          if (status != IncidentStatus.resolved)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: const Color(0xFFE3DCF8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: event != null ? ink : muted,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                event == null
                                    ? 'Awaiting this step'
                                    : dateLabel(event.at),
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                              if (event != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    event.note,
                                    style: const TextStyle(height: 1.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              const SectionTitle('Description'),
              const SizedBox(height: 12),
              Text(incident.description, style: const TextStyle(height: 1.6)),
              const SizedBox(height: 24),
              if (incident.photoPath.isNotEmpty) ...[
                const SectionTitle('Attached photo'),
                const SizedBox(height: 12),
                IncidentPhoto(incident.photoPath),
                const SizedBox(height: 24),
              ],
              if (session.isStaff && incident.status.next != null) ...[
                const SectionTitle('Staff actions'),
                const SizedBox(height: 8),
                const Text(
                  'Add a clear update so the student knows what happens next.',
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 12),
                BusyButton(
                  label: 'Mark as ${incident.status.next!.label.toLowerCase()}',
                  busy: _busy,
                  onPressed: () => _advance(incident),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDialog extends StatefulWidget {
  const _StatusDialog(this.next);
  final IncidentStatus next;
  @override
  State<_StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<_StatusDialog> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Mark as ${widget.next.label.toLowerCase()}'),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _note,
        minLines: 2,
        maxLines: 4,
        maxLength: 300,
        decoration: const InputDecoration(
          labelText: 'Update note',
          hintText: 'What has been done?',
        ),
        validator: (v) => Validation.text(v, 'Update note', 5, 300),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _note.text.trim());
          }
        },
        child: const Text('Update status'),
      ),
    ],
  );
}
