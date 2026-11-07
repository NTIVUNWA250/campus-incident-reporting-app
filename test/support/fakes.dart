import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_care/data/incident_repository.dart';
import 'package:campus_care/models/incident.dart';
import 'package:campus_care/state/session_controller.dart';

class FakeUser extends Fake implements User {
  @override
  String get uid => 'student';
  @override
  String get email => 'amina@alustudent.com';
  @override
  bool get emailVerified => true;
}

class FakeSession extends ChangeNotifier implements SessionController {
  FakeSession({this.isStaff = false});
  @override
  User? user = FakeUser();
  @override
  bool isStaff;
  @override
  bool loading = false;
  @override
  bool busy = false;
  @override
  String? error;
  @override
  bool get verified => true;
  @override
  String get name => 'Amina Hassan';
  @override
  Future<void> signIn(String email, String password) async {}
  @override
  Future<void> register(String name, String email, String password) async {}
  @override
  Future<void> resetPassword(String email) async {}
  @override
  Future<void> sendVerification() async {}
  @override
  Future<void> refresh() async {}
  @override
  Future<void> signOut() async {
    user = null;
    notifyListeners();
  }
}

class FakeRepository implements IncidentRepository {
  FakeRepository([this.items = const []]);
  List<Incident> items;
  final changes = StreamController<List<Incident>>.broadcast();
  int creates = 0;
  @override
  Stream<List<Incident>> watch(String uid, bool staff, int limit) async* {
    yield items;
    yield* changes.stream;
  }

  @override
  Future<String?> create(
    IncidentDraft draft,
    String uid,
    String name,
    Uint8List? photo,
  ) async {
    draft.toMap();
    creates++;
    return null;
  }

  @override
  Future<void> edit(Incident incident, IncidentDraft draft) async {
    draft.toMap();
  }

  @override
  Future<void> attach(Incident incident, Uint8List photo) async {}
  @override
  Future<void> delete(Incident incident) async {}
  @override
  Future<void> advance(Incident incident, String staffId, String note) async {}
  @override
  Future<Uint8List?> photo(String path) async => null;
}
