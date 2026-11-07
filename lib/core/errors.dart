import 'package:firebase_core/firebase_core.dart';

String friendlyError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email or password is incorrect.',
      'email-already-in-use' =>
        'An account already uses this email. Try signing in.',
      'weak-password' => 'Choose a stronger password of at least 8 characters.',
      'too-many-requests' => 'Too many attempts. Please wait and try again.',
      'network-request-failed' ||
      'unavailable' => 'Unable to connect. Check your connection and retry.',
      'permission-denied' || 'unauthorized' =>
        'Access denied. Refresh your session and check your permissions.',
      'requires-recent-login' => 'Please sign in again to continue.',
      'failed-precondition' =>
        'This report changed or Firebase setup is incomplete. Refresh and retry.',
      'object-not-found' => 'This photo is no longer available.',
      _ => 'The request failed (${error.code}). Please try again.',
    };
  }
  if (error is StateError) return error.message.toString();
  return 'Something went wrong. Please try again.';
}
