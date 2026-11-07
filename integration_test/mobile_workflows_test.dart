import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:campus_care/main.dart' as app;
import 'package:campus_care/core/firebase_config.dart';
import 'package:campus_care/models/incident.dart';
import 'package:campus_care/data/incident_repository.dart';
import 'package:campus_care/screens/home_screen.dart';
import 'package:campus_care/screens/incident_detail_screen.dart';
import 'package:campus_care/screens/incident_form_screen.dart';
import 'package:campus_care/screens/reports_screen.dart';
import 'package:campus_care/screens/profile_screen.dart';
import 'package:campus_care/state/incident_controller.dart';
import 'package:campus_care/widgets/report_card.dart';

Finder reportTitle(String title) =>
    find.descendant(of: find.byType(ReportCard), matching: find.text(title));

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(
    finder,
    findsWidgets,
    reason: 'Expected screen did not appear within 20 seconds.',
  );
}

Future<void> captureEvidence(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  debugPrint('EVIDENCE:$name');
  await tester.pump(const Duration(seconds: 3));
}

Future<void> showAndTap(
  WidgetTester tester,
  Finder finder, {
  Finder? within,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
  if (within != null) {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find
          .descendant(of: within, matching: find.byType(Scrollable))
          .first,
    );
  } else {
    await tester.ensureVisible(finder);
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android Firebase authentication, report CRUD, photo and staff status workflow',
    (tester) async {
      expect(
        useEmulators,
        isTrue,
        reason: 'This test is restricted to local Firebase emulators.',
      );
      await app.main();
      await FirebaseAuth.instance.signOut();
      await waitFor(tester, find.text('New here? Create an account'));
      await captureEvidence(tester, 'auth');
      await tester.tap(find.text('New here? Create an account'));
      await tester.pumpAndSettle();
      final email =
          'mobile-${DateTime.now().millisecondsSinceEpoch}@alustudent.com';
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Mobile Test Student',
      );
      await tester.enterText(find.byType(TextFormField).at(1), email);
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'CampusCare123!',
      );
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'CampusCare123!',
      );
      await showAndTap(tester, find.text('Create account'));
      await waitFor(tester, find.text('Check your ALU inbox'));
      expect(FirebaseAuth.instance.currentUser!.emailVerified, isFalse);
      // The emulator admin endpoint simulates opening the verification email.
      final response = await http.post(
        Uri.parse(
          'http://$emulatorHost:9099/identitytoolkit.googleapis.com/v1/projects/demo-campus-care/accounts:update',
        ),
        headers: {
          'Authorization': 'Bearer owner',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'localId': FirebaseAuth.instance.currentUser!.uid,
          'emailVerified': true,
        }),
      );
      expect(response.statusCode, 200);
      await tester.tap(find.text('I have verified my email'));
      await waitFor(tester, find.byType(AppShell));
      expect(FirebaseAuth.instance.currentUser!.emailVerified, isTrue);
      await tester.pumpAndSettle();
      await captureEvidence(tester, 'home');
      await tester.tap(find.text('Report an issue'));
      await tester.pumpAndSettle();
      await captureEvidence(tester, 'form');
      await tester.tap(find.text('Water'));
      await tester.pumpAndSettle();
      final title =
          'Water shortage - ${DateTime.now().millisecondsSinceEpoch % 100000}';
      await tester.enterText(
        find.byKey(const ValueKey('incident-title')),
        title,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('incident-description')),
        180,
        scrollable: find
            .descendant(
              of: find.byType(IncidentFormScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(
        find.byKey(const ValueKey('incident-description')),
        'No water in the residence since this morning. Please inspect the main supply.',
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('incident-location')),
        180,
        scrollable: find
            .descendant(
              of: find.byType(IncidentFormScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(
        find.byKey(const ValueKey('incident-location')),
        'Student Residence - Floor 2',
      );
      await showAndTap(
        tester,
        find.text('Submit report'),
        within: find.byType(IncidentFormScreen),
      );
      await waitFor(tester, find.byType(AppShell));
      await tester.tap(find.text('Reports').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        reportTitle(title),
        180,
        scrollable: find
            .descendant(
              of: find.byType(ReportsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await captureEvidence(tester, 'reports');
      final controller = tester
          .element(find.byType(AppShell))
          .read<IncidentController>();
      final incident = controller.incidents.firstWhere((i) => i.title == title);
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGMocPz6HwAFcQKmW+4ckAAAAABJRU5ErkJggg==',
      );
      // Verify SDK edit and delete behavior on a separate, temporary report.
      final repository = controller.repository;
      final temporaryTitle =
          'Temporary mobile CRUD ${DateTime.now().millisecondsSinceEpoch}';
      await repository.create(
        IncidentDraft(
          title: temporaryTitle,
          description:
              'Temporary mobile test report for validating edit and deletion.',
          location: 'Block B - Room 204',
          category: IncidentCategory.facilities,
        ),
        incident.ownerId,
        'Mobile Test Student',
        png,
      );
      final temporary =
          (await repository
                  .watch(incident.ownerId, false, 100)
                  .firstWhere(
                    (items) => items.any((i) => i.title == temporaryTitle),
                  ))
              .firstWhere((i) => i.title == temporaryTitle);
      await repository.edit(
        temporary,
        IncidentDraft(
          title: temporaryTitle,
          description:
              'Updated description saved and retrieved through Firebase.',
          location: 'Block B - Room 205',
          category: IncidentCategory.facilities,
        ),
      );
      await repository.delete(temporary);
      await repository
          .watch(incident.ownerId, false, 100)
          .firstWhere((items) => !items.any((i) => i.id == temporary.id));
      await controller.repository.attach(incident, png);
      final photo = await controller.repository.photo(
        'incidents/${incident.ownerId}/${incident.id}/photo',
      );
      expect(photo, orderedEquals(png));
      await tester.tap(reportTitle(title));
      await tester.pumpAndSettle();
      expect(find.text('Status timeline'), findsOneWidget);
      expect(find.text('Staff actions'), findsNothing);
      await captureEvidence(tester, 'details');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await showAndTap(
        tester,
        find.text('Sign out'),
        within: find.byType(ProfileScreen),
      );
      await waitFor(tester, find.text('Sign in'));
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'staff@alueducation.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'CampusCare123!',
      );
      await showAndTap(tester, find.text('Sign in'));
      await waitFor(tester, find.byType(AppShell));
      await tester.tap(find.text('Reports').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, title);
      await tester.pumpAndSettle();
      await showAndTap(
        tester,
        reportTitle(title),
        within: find.byType(ReportsScreen),
      );
      for (final label in ['in progress', 'resolved']) {
        await showAndTap(
          tester,
          find.text('Mark as $label'),
          within: find.byType(IncidentDetailScreen),
        );
        await tester.enterText(
          find.byType(TextFormField),
          'Campus support update: issue is $label.',
        );
        if (label == 'in progress') {
          await captureEvidence(tester, 'staff');
        }
        await tester.tap(find.text('Update status'));
        await tester.pumpAndSettle();
        ScaffoldMessenger.of(
          tester.element(find.byType(IncidentDetailScreen)),
        ).hideCurrentSnackBar();
        await tester.pumpAndSettle();
      }
      final staffController = tester
          .element(find.byType(IncidentDetailScreen))
          .read<IncidentController>();
      final resolved = staffController.incidents.firstWhere(
        (i) => i.id == incident.id,
      );
      expect(resolved.status, IncidentStatus.resolved);
      expect(resolved.history.length, 3);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await showAndTap(
        tester,
        find.text('Sign out'),
        within: find.byType(ProfileScreen),
      );
      await waitFor(tester, find.text('Sign in'));
      await tester.enterText(find.byType(TextFormField).at(0), email);
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'CampusCare123!',
      );
      await showAndTap(tester, find.text('Sign in'));
      await waitFor(tester, find.byType(AppShell));
      await tester.tap(find.text('Reports').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, title);
      await tester.pumpAndSettle();
      await waitFor(tester, reportTitle(title));
      expect(find.text('Resolved'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
