import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/firebase_config.dart';
import 'data/incident_repository.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'state/incident_controller.dart';
import 'state/session_controller.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeFirebase();
    runApp(
      ChangeNotifierProvider(
        create: (_) => SessionController(FirebaseAuth.instance),
        child: const CampusCareApp(),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        home: const Scaffold(
          body: SafeArea(
            child: Center(
              child: EmptyState(
                title: 'Setup needed',
                icon: Icons.settings_outlined,
                message:
                    'Start the local Firebase emulators and use the Local Firebase launch configuration, or supply your Firebase project configuration.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CampusCareApp extends StatelessWidget {
  const CampusCareApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Campus Care',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: const _SessionGate(),
  );
}

class _SessionGate extends StatelessWidget {
  const _SessionGate();
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    if (session.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (session.error != null) {
      return Scaffold(
        body: Center(
          child: EmptyState(
            title: 'Session unavailable',
            message: session.error!,
            action: TextButton(
              onPressed: () => performAction(context, session.refresh),
              child: const Text('Retry'),
            ),
          ),
        ),
      );
    }
    if (session.user == null) return const AuthScreen();
    if (!session.verified) return const VerifyEmailScreen();
    return ChangeNotifierProvider(
      key: ValueKey('${session.user!.uid}:${session.isStaff}'),
      create: (_) => IncidentController(
        FirebaseIncidentRepository(
          FirebaseFirestore.instance,
          FirebaseStorage.instance,
        ),
        session.user!.uid,
        session.isStaff,
      ),
      child: Navigator(
        onGenerateRoute: (_) =>
            MaterialPageRoute<void>(builder: (_) => const AppShell()),
      ),
    );
  }
}
