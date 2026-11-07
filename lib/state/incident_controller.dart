import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/errors.dart';
import '../data/incident_repository.dart';
import '../models/incident.dart';

class IncidentController extends ChangeNotifier {
  IncidentController(this.repository, this.uid, this.staff) {
    reload();
  }
  final IncidentRepository repository;
  final String uid;
  final bool staff;
  StreamSubscription<List<Incident>>? _subscription;
  List<Incident> incidents = [];
  String query = '';
  IncidentCategory? category;
  IncidentStatus? status;
  String? error;
  bool loading = true;
  int limit = 100;
  bool _disposed = false;
  List<Incident> get filtered => filterIncidents(
    incidents,
    query: query,
    category: category,
    status: status,
  );
  bool get canLoadMore => incidents.length >= limit;
  void filters({
    String? search,
    IncidentCategory? category,
    IncidentStatus? status,
    bool reset = false,
  }) {
    query = reset ? '' : search ?? query;
    this.category = reset ? null : category;
    this.status = reset ? null : status;
    notifyListeners();
  }

  void reload({bool more = false}) {
    if (more) limit += 100;
    _subscription?.cancel();
    loading = true;
    error = null;
    _subscription = repository
        .watch(uid, staff, limit)
        .listen(
          (items) {
            if (_disposed) return;
            incidents = items;
            loading = false;
            error = null;
            notifyListeners();
          },
          onError: (Object e) {
            if (_disposed) return;
            error = friendlyError(e);
            loading = false;
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
