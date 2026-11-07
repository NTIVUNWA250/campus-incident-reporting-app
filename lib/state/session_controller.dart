import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/errors.dart';
import '../core/validation.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._auth) {
    _subscription = _auth.userChanges().listen(
      _onUser,
      onError: (Object e) {
        loading = false;
        error = friendlyError(e);
        notifyListeners();
      },
    );
  }
  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _subscription;
  User? user;
  bool loading = true, isStaff = false, busy = false;
  String? error;
  int _generation = 0;
  bool _disposed = false;
  bool get verified =>
      user != null &&
      user!.emailVerified &&
      Validation.email(user!.email) == null;
  String get name => (user?.displayName?.trim().isNotEmpty ?? false)
      ? user!.displayName!
      : 'Student';

  Future<void> _onUser(User? value) async {
    final generation = ++_generation;
    user = value;
    isStaff = false;
    error = null;
    loading = value != null;
    if (!_disposed) notifyListeners();
    try {
      if (value != null) {
        final token = await value.getIdTokenResult();
        if (generation != _generation || _disposed) return;
        isStaff = token.claims?['staff'] == true;
      }
    } catch (e) {
      if (generation == _generation) error = friendlyError(e);
    } finally {
      if (generation == _generation && !_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) => _run(() async {
    if (Validation.email(email) != null)
      throw StateError('Use your ALU email address.');
    await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  });
  Future<void> register(String name, String email, String password) =>
      _run(() async {
        if (Validation.email(email) != null ||
            Validation.text(name, 'Name', 2, 60) != null ||
            Validation.password(password) != null) {
          throw StateError('Check your name, ALU email and password.');
        }
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim().toLowerCase(),
          password: password,
        );
        await credential.user!.updateDisplayName(name.trim());
        await credential.user!.sendEmailVerification();
      });
  Future<void> resetPassword(String email) => _run(() async {
    if (Validation.email(email) != null)
      throw StateError('Enter a valid ALU email first.');
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  });
  Future<void> sendVerification() =>
      _run(() => _auth.currentUser!.sendEmailVerification());
  Future<void> refresh() => _run(() async {
    await _auth.currentUser?.reload();
    await _auth.currentUser?.getIdToken(true);
    await _onUser(_auth.currentUser);
  });
  Future<void> signOut() => _run(_auth.signOut);
  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _subscription.cancel();
    super.dispose();
  }
}
