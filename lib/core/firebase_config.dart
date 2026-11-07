import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
const emulatorHost = String.fromEnvironment(
  'EMULATOR_HOST',
  defaultValue: '10.0.2.2',
);

Future<void> initializeFirebase() async {
  if (useEmulators && kReleaseMode) {
    throw StateError('Emulators are available only in debug builds.');
  }
  const project = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const key = String.fromEnvironment('FIREBASE_API_KEY');
  const app = String.fromEnvironment('FIREBASE_APP_ID');
  const sender = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  const bucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  if (!useEmulators &&
      [project, key, app, sender, bucket].any((s) => s.isEmpty)) {
    throw StateError(
      'Firebase is not configured. Use the local emulator launch configuration or supply config/firebase.json.',
    );
  }
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: useEmulators ? 'demo-api-key' : key,
      appId: useEmulators ? '1:1234567890:android:0123456789abcdef' : app,
      messagingSenderId: useEmulators ? '1234567890' : sender,
      projectId: useEmulators ? 'demo-campus-care' : project,
      storageBucket: useEmulators ? 'demo-campus-care.appspot.com' : bucket,
      iosBundleId: 'com.ntivunwa.campusCare',
    ),
  );
  if (useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8088);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    await FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
  } else {
    // Avoid retaining sensitive reports on shared school devices after logout.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }
}
