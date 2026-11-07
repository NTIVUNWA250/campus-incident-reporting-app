import 'package:cloud_firestore/cloud_firestore.dart';

enum IncidentCategory {
  facilities('Facilities'),
  water('Water'),
  electricity('Electricity'),
  furniture('Furniture'),
  safety('Safety'),
  sanitation('Sanitation');

  const IncidentCategory(this.label);
  final String label;
}

enum IncidentStatus {
  submitted('Submitted'),
  inProgress('In Progress'),
  resolved('Resolved');

  const IncidentStatus(this.label);
  final String label;
  IncidentStatus? get next => switch (this) {
    submitted => inProgress,
    inProgress => resolved,
    resolved => null,
  };
}

class StatusEvent {
  const StatusEvent({
    required this.status,
    required this.at,
    required this.by,
    required this.note,
  });
  final IncidentStatus status;
  final DateTime? at;
  final String by;
  final String note;
  factory StatusEvent.fromMap(Map<String, dynamic> data) => StatusEvent(
    status: IncidentStatus.values.byName(data['status'] as String),
    at: (data['at'] as Timestamp?)?.toDate(),
    by: data['by'] as String,
    note: data['note'] as String,
  );
}

class Incident {
  const Incident({
    required this.id,
    required this.ownerId,
    required this.reporterName,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.status,
    required this.photoPath,
    required this.createdAt,
    required this.updatedAt,
    required this.history,
  });
  final String id,
      ownerId,
      reporterName,
      title,
      description,
      location,
      photoPath;
  final IncidentCategory category;
  final IncidentStatus status;
  final DateTime? createdAt, updatedAt;
  final List<StatusEvent> history;

  factory Incident.fromMap(String id, Map<String, dynamic> data) => Incident(
    id: id,
    ownerId: data['ownerId'] as String,
    reporterName: data['reporterName'] as String,
    title: data['title'] as String,
    description: data['description'] as String,
    location: data['location'] as String,
    category: IncidentCategory.values.byName(data['category'] as String),
    status: IncidentStatus.values.byName(data['status'] as String),
    photoPath: data['photoPath'] as String,
    createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    history:
        (data['history'] as Map<String, dynamic>).values
            .map(
              (e) => StatusEvent.fromMap(Map<String, dynamic>.from(e as Map)),
            )
            .toList()
          ..sort((a, b) => a.status.index.compareTo(b.status.index)),
  );
}

List<Incident> filterIncidents(
  List<Incident> source, {
  String query = '',
  IncidentCategory? category,
  IncidentStatus? status,
}) {
  final needle = query.trim().toLowerCase();
  return source
      .where(
        (item) =>
            (category == null || item.category == category) &&
            (status == null || item.status == status) &&
            '${item.title} ${item.description} ${item.location}'
                .toLowerCase()
                .contains(needle),
      )
      .toList();
}
