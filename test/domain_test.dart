import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_care/core/photo_data.dart';
import 'package:campus_care/core/validation.dart';
import 'package:campus_care/models/incident.dart';
import 'package:campus_care/data/incident_repository.dart';

Incident sample({
  String id = '1',
  String title = 'Water shortage',
  IncidentCategory category = IncidentCategory.water,
  IncidentStatus status = IncidentStatus.submitted,
}) => Incident(
  id: id,
  ownerId: 'student',
  reporterName: 'Amina Hassan',
  title: title,
  description: 'The residence has had no water since this morning.',
  location: 'Student Residence',
  category: category,
  status: status,
  photoPath: '',
  createdAt: DateTime(2026, 11, 7),
  updatedAt: DateTime(2026, 11, 7),
  history: const [],
);

void main() {
  test('ALU emails are normalized and lookalike domains are rejected', () {
    expect(Validation.email(' AMINA@ALUSTUDENT.COM '), isNull);
    expect(Validation.email('staff@alueducation.com'), isNull);
    for (final value in [
      'a@gmail.com',
      'a@fakealustudent.com',
      'a@alustudent.com.evil',
      '@alustudent.com',
      'a b@alustudent.com',
    ]) {
      expect(Validation.email(value), isNotNull);
    }
  });
  test(
    'ASCII validation allows multiline text and rejects Unicode and controls',
    () {
      expect(
        Validation.text('Line one\nLine two', 'Description', 5, 50),
        isNull,
      );
      expect(
        Validation.text('Water \u2014 shortage', 'Title', 5, 50),
        isNotNull,
      );
      expect(Validation.text('Water\tshortage', 'Title', 5, 50), isNotNull);
      expect(Validation.text('   ', 'Title', 5, 50), isNotNull);
      expect(Validation.password('short'), isNotNull);
      expect(Validation.password('CampusCare123!'), isNull);
    },
  );
  test(
    'search combines category and status filters without changing source',
    () {
      final reports = [
        sample(),
        sample(
          id: '2',
          title: 'Overflowing bin',
          category: IncidentCategory.sanitation,
          status: IncidentStatus.resolved,
        ),
      ];
      expect(
        filterIncidents(
          reports,
          query: ' RESIDENCE ',
          category: IncidentCategory.water,
        ).map((i) => i.id),
        ['1'],
      );
      expect(
        filterIncidents(
          reports,
          query: 'bin',
          status: IncidentStatus.resolved,
        ).length,
        1,
      );
      expect(
        filterIncidents(
          reports,
          query: 'bin',
          category: IncidentCategory.water,
        ),
        isEmpty,
      );
      expect(reports.length, 2);
    },
  );
  test('draft validation runs before database writes', () {
    const invalid = IncidentDraft(
      title: 'Bad',
      description: 'Too short',
      location: '',
      category: IncidentCategory.facilities,
    );
    expect(invalid.toMap, throwsStateError);
  });
  test('photo validation checks type and size before upload', () {
    expect(
      photoContentType(Uint8List.fromList([255, 216, 255, 0])),
      'image/jpeg',
    );
    expect(
      photoContentType(Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10])),
      'image/png',
    );
    expect(
      () => photoContentType(Uint8List(5 * 1024 * 1024 + 1)),
      throwsStateError,
    );
    expect(
      () => photoContentType(Uint8List.fromList([1, 2, 3])),
      throwsStateError,
    );
  });
}
