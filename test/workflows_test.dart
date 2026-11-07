import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:campus_care/core/app_theme.dart';
import 'package:campus_care/screens/home_screen.dart';
import 'package:campus_care/screens/incident_detail_screen.dart';
import 'package:campus_care/screens/incident_form_screen.dart';
import 'package:campus_care/state/session_controller.dart';
import 'package:campus_care/state/incident_controller.dart';
import 'domain_test.dart' show sample;
import 'support/fakes.dart';

Widget harness(
  FakeRepository repository, {
  bool staff = false,
  Widget child = const AppShell(),
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<SessionController>(
      create: (_) => FakeSession(isStaff: staff),
    ),
    ChangeNotifierProvider(
      create: (_) => IncidentController(repository, 'student', staff),
    ),
  ],
  child: MaterialApp(theme: appTheme(), home: child),
);

void main() {
  testWidgets(
    'small phone dashboard and reporting form have no layout errors',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeRepository();
      await tester.pumpWidget(harness(repository));
      await tester.pumpAndSettle();
      expect(find.text('Hello, Amina'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Report an issue'));
      await tester.pumpAndSettle();
      expect(find.text('Select a category'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Submit report'),
        250,
        scrollable: find
            .descendant(
              of: find.byType(IncidentFormScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();
      expect(repository.creates, 0);
      expect(find.text('Title must be 5-100 characters.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('search filters report list and updates from shared stream', (
    tester,
  ) async {
    final repository = FakeRepository([sample()]);
    await tester.pumpWidget(harness(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reports').last);
    await tester.pumpAndSettle();
    expect(find.text('Water shortage'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'projector');
    await tester.pumpAndSettle();
    expect(find.text('No matching reports'), findsOneWidget);
    repository.changes.add([sample(title: 'Broken projector')]);
    await tester.pumpAndSettle();
    expect(find.text('Broken projector'), findsOneWidget);
  });
  testWidgets('status actions are visible only to staff', (tester) async {
    final repository = FakeRepository([sample()]);
    await tester.pumpWidget(
      harness(repository, child: const IncidentDetailScreen('1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Staff actions'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pumpWidget(
      harness(
        FakeRepository([sample()]),
        staff: true,
        child: const IncidentDetailScreen('1'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Staff actions'), 300);
    expect(find.text('Mark as in progress'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('controller receives live reports and filter changes', () async {
    final repository = FakeRepository([sample()]);
    final controller = IncidentController(repository, 'student', false);
    await Future<void>.delayed(Duration.zero);
    expect(controller.incidents.length, 1);
    controller.filters(search: 'projector');
    expect(controller.filtered, isEmpty);
    repository.changes.add([sample(title: 'Broken projector')]);
    await Future<void>.delayed(Duration.zero);
    expect(controller.filtered.length, 1);
    controller.dispose();
    await repository.changes.close();
  });
}
