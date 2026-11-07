import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/incident.dart';
import '../state/incident_controller.dart';
import '../screens/incident_detail_screen.dart';
import 'common.dart';

class ReportCard extends StatelessWidget {
  const ReportCard(this.incident, {super.key});
  final Incident incident;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => IncidentDetailScreen(incident.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 68,
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    incident.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    dateLabel(incident.createdAt),
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              children: [
                StatusBadge(incident.status),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, color: muted, size: 20),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class IncidentPhoto extends StatefulWidget {
  const IncidentPhoto(this.path, {super.key});
  final String path;
  @override
  State<IncidentPhoto> createState() => _IncidentPhotoState();
}

class _IncidentPhotoState extends State<IncidentPhoto> {
  Future<Uint8List?>? _future;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.read<IncidentController>().repository.photo(
      widget.path,
    );
  }

  @override
  void didUpdateWidget(covariant IncidentPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _future = context.read<IncidentController>().repository.photo(
        widget.path,
      );
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return EmptyState(
          title: 'Photo unavailable',
          message: 'Check your connection and retry.',
          action: TextButton(
            onPressed: () => setState(
              () => _future = context
                  .read<IncidentController>()
                  .repository
                  .photo(widget.path),
            ),
            child: const Text('Retry photo'),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
          width: double.infinity,
          semanticLabel: 'Incident attachment',
          errorBuilder: (_, error, stackTrace) =>
              const Text('This image could not be displayed.'),
        ),
      );
    },
  );
}
