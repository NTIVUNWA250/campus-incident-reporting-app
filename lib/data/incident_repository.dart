import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/incident.dart';
import '../core/validation.dart';

class IncidentDraft {
  const IncidentDraft({
    required this.title,
    required this.description,
    required this.location,
    required this.category,
  });
  final String title, description, location;
  final IncidentCategory category;
  Map<String, dynamic> toMap() {
    for (final result in [
      Validation.text(title, 'Title', 5, 100),
      Validation.text(description, 'Description', 20, 2000),
      Validation.text(location, 'Location', 3, 120),
    ]) {
      if (result != null) throw StateError(result);
    }
    return {
      'title': title.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'category': category.name,
    };
  }
}

abstract class IncidentRepository {
  Stream<List<Incident>> watch(String uid, bool staff, int limit);
  Future<String?> create(
    IncidentDraft draft,
    String uid,
    String name,
    Uint8List? photo,
  );
  Future<void> edit(Incident incident, IncidentDraft draft);
  Future<void> delete(Incident incident);
  Future<void> advance(Incident incident, String staffId, String note);
  Future<Uint8List?> photo(String path);
}

class FirebaseIncidentRepository implements IncidentRepository {
  FirebaseIncidentRepository(this.db, this.storage);
  final FirebaseFirestore db;
  final FirebaseStorage storage;
  CollectionReference<Map<String, dynamic>> get reports =>
      db.collection('incidents');

  @override
  Stream<List<Incident>> watch(String uid, bool staff, int limit) {
    Query<Map<String, dynamic>> query = reports;
    if (!staff) query = query.where('ownerId', isEqualTo: uid);
    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Incident.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<String?> create(
    IncidentDraft draft,
    String uid,
    String name,
    Uint8List? photo,
  ) async {
    final reference = reports.doc();
    if (photo != null && photo.length > 5 * 1024 * 1024)
      throw StateError('Choose a photo smaller than 5 MB.');
    await reference.set({
      ...draft.toMap(),
      'ownerId': uid,
      'reporterName': name,
      'status': 'submitted',
      'photoPath': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'history': {
        'submitted': {
          'status': 'submitted',
          'by': uid,
          'at': FieldValue.serverTimestamp(),
          'note': 'Report submitted.',
        },
      },
    });
    if (photo == null) return null;
    final path = 'incidents/$uid/${reference.id}/photo.jpg';
    final object = storage.ref(path);
    try {
      await object.putData(photo, SettableMetadata(contentType: 'image/jpeg'));
      await reference.update({
        'photoPath': path,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (_) {
      try {
        await object.delete();
      } catch (_) {
        /* Best-effort orphan cleanup. */
      }
      return 'Your report was saved, but its photo could not be attached. You can add it by editing the submitted report.';
    }
  }

  @override
  Future<void> edit(Incident incident, IncidentDraft draft) async {
    await reports.doc(incident.id).update({
      ...draft.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> attach(Incident incident, Uint8List photo) async {
    if (photo.length > 5 * 1024 * 1024)
      throw StateError('Choose a photo smaller than 5 MB.');
    final path = 'incidents/${incident.ownerId}/${incident.id}/photo.jpg';
    await storage
        .ref(path)
        .putData(photo, SettableMetadata(contentType: 'image/jpeg'));
    await reports.doc(incident.id).update({
      'photoPath': path,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> delete(Incident incident) async {
    // Keep the parent record until photo cleanup succeeds so Storage rules can authorize it.
    if (incident.photoPath.isNotEmpty) {
      try {
        await storage.ref(incident.photoPath).delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') rethrow;
      }
    }
    await reports.doc(incident.id).delete();
  }

  @override
  Future<void> advance(Incident incident, String staffId, String note) async {
    if (Validation.text(note, 'Update note', 5, 300) != null)
      throw StateError('Write an update note of 5-300 ASCII characters.');
    await db.runTransaction((transaction) async {
      final reference = reports.doc(incident.id);
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) throw StateError('This report has been deleted.');
      final current = IncidentStatus.values.byName(
        snapshot.data()!['status'] as String,
      );
      if (current != incident.status)
        throw StateError(
          'This report was updated by someone else. Review the latest status.',
        );
      final next = current.next;
      if (next == null) throw StateError('This report is already resolved.');
      transaction.update(reference, {
        'status': next.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'history.${next.name}': {
          'status': next.name,
          'by': staffId,
          'at': FieldValue.serverTimestamp(),
          'note': note.trim(),
        },
      });
    });
  }

  @override
  Future<Uint8List?> photo(String path) =>
      storage.ref(path).getData(5 * 1024 * 1024);
}
