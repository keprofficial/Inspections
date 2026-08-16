import 'package:flutter_test/flutter_test.dart';
import 'package:kepr/constants/severity.dart';
import 'package:kepr/models/models.dart';
import 'package:kepr/services/submit_validation.dart';

/// A valid public Supabase storage URL for the configured project.
const validPhotoUrl =
    'https://egalrsutygdvdmjkvduh.supabase.co/storage/v1/object/public/'
    'inspection-photos/x.jpg';

InspectionItem item({
  required String id,
  String severity = 'no_issue',
  bool completed = true,
  String? notes = 'notes',
  List<String> photoPaths = const [],
  List<String> photoEvidenceBase64 = const [],
  List<InspectionSelectedService> services = const [],
}) {
  return InspectionItem(
    id: id,
    name: 'Check $id',
    category: 'General',
    description: 'desc',
    severity: severity,
    completed: completed,
    notes: notes,
    photoPaths: photoPaths,
    photoEvidenceBase64: photoEvidenceBase64,
    selectedServices: services,
  );
}

InspectionArea area(List<InspectionItem> items) {
  return InspectionArea(
    id: 'area-1',
    name: 'Kitchen',
    icon: 'kitchen',
    templateKey: 'kitchen',
    progress: 0,
    status: 'pending',
    issues: items.length,
    items: items,
  );
}

/// Five completed no-issue checks — the minimum a standard plan needs.
List<InspectionArea> baselineAreas() {
  return [
    area([for (var i = 0; i < 5; i++) item(id: 'ok-$i')]),
  ];
}

bool areaHasRecordedCritical(InspectionArea a) => a.items.any(
      (i) => i.completed && Severity.fromValue(i.severity) == Severity.critical,
    );

void main() {
  group('area critical flag', () {
    test('an untouched template item does not make an area critical', () {
      // Templates seed a severity on every item before inspection.
      final a = area([
        item(id: 'seeded', severity: 'critical', completed: false),
      ]);

      expect(areaHasRecordedCritical(a), isFalse);
    });

    test('a recorded critical finding does flag the area', () {
      final a = area([
        item(id: 'found', severity: 'critical', completed: true),
      ]);

      expect(areaHasRecordedCritical(a), isTrue);
    });
  });

  group('severity rules', () {
    test('no issue requires no photo, notes, or service', () {
      expect(Severity.noIssue.requiresPhoto, isFalse);
      expect(Severity.noIssue.requiresNotes, isFalse);
      expect(Severity.noIssue.requiresService, isFalse);
    });

    test('low and medium do not require photo evidence', () {
      expect(Severity.low.requiresPhoto, isFalse);
      expect(Severity.medium.requiresPhoto, isFalse);
    });

    test('high and critical require a photo and notes', () {
      for (final severity in [Severity.high, Severity.critical]) {
        expect(severity.requiresPhoto, isTrue, reason: severity.label);
        expect(severity.requiresNotes, isTrue, reason: severity.label);
      }
    });

    test('only critical requires a service', () {
      expect(Severity.critical.requiresService, isTrue);
      expect(Severity.high.requiresService, isFalse);
    });

    test('stored values round-trip', () {
      for (final severity in Severity.values) {
        expect(Severity.fromValue(severity.value), severity);
      }
      expect(Severity.fromValue('none'), Severity.noIssue);
      expect(Severity.fromValue(null), isNull);
    });
  });

  group('validateForSubmit', () {
    test('a clean standard inspection has no blockers', () {
      expect(
        SubmitValidator.validate(areas: baselineAreas(), isAdhoc: false),
        isEmpty,
      );
    });

    test('standard plans need at least five completed checks', () {
      final areas = [
        area([for (var i = 0; i < 4; i++) item(id: 'ok-$i')]),
      ];
      final blockers = SubmitValidator.validate(areas: areas, isAdhoc: false);

      expect(blockers, hasLength(1));
      expect(blockers.single.title, 'Not enough checks completed');
      expect(blockers.single.detail, contains('at least 5'));
    });

    test('ad-hoc plans are exempt from the five-check rule', () {
      final areas = [
        area([item(id: 'only-one')]),
      ];
      final blockers = SubmitValidator.validate(areas: areas, isAdhoc: true);

      expect(blockers, isEmpty);
    });

    test('ad-hoc plans need at least one check', () {
      final blockers = SubmitValidator.validate(
        areas: [area(const [])],
        isAdhoc: true,
      );

      expect(blockers, hasLength(1));
      expect(blockers.single.title, 'No checks added');
    });

    test('high severity without notes is blocked and names the item', () {
      final areas = [
        area([
          ...baselineAreas().single.items,
          item(
            id: 'high-1',
            severity: 'high',
            notes: '   ',
            photoPaths: const [validPhotoUrl],
          ),
        ]),
      ];
      final blockers = SubmitValidator.validate(areas: areas, isAdhoc: false);

      final notesBlocker =
          blockers.firstWhere((b) => b.title == 'Notes missing');
      expect(notesBlocker.targets, hasLength(1));
      expect(notesBlocker.targets.single.itemId, 'high-1');
      expect(notesBlocker.targets.single.areaId, 'area-1');
    });

    test('critical without a service is blocked', () {
      final areas = [
        area([
          ...baselineAreas().single.items,
          item(
            id: 'crit-1',
            severity: 'critical',
            photoPaths: const [validPhotoUrl],
          ),
        ]),
      ];
      final blockers = SubmitValidator.validate(areas: areas, isAdhoc: false);

      expect(
        blockers.any((b) => b.title == 'Service not selected'),
        isTrue,
      );
    });

    test('critical photo saved locally but not uploaded is blocked', () {
      final areas = [
        area([
          ...baselineAreas().single.items,
          item(
            id: 'crit-2',
            severity: 'critical',
            photoEvidenceBase64: const ['abc'],
            services: const [
              InspectionSelectedService(
                serviceCode: 's001',
                name: 'Service',
                estimatedCost: 150,
              ),
            ],
          ),
        ]),
      ];
      final blockers = SubmitValidator.validate(areas: areas, isAdhoc: false);

      expect(
        blockers.any((b) => b.title == 'Photos not uploaded'),
        isTrue,
      );
    });

    test('a non-Supabase photo URL is rejected', () {
      final areas = [
        area([
          ...baselineAreas().single.items,
          item(id: 'bad-url', photoPaths: const ['https://evil.test/x.jpg']),
        ]),
      ];
      final blockers = SubmitValidator.validate(areas: areas, isAdhoc: false);

      expect(blockers.any((b) => b.title == 'Invalid photo link'), isTrue);
    });

    test('low and medium findings are not blocked for missing photos', () {
      final areas = [
        area([
          for (var i = 0; i < 3; i++) item(id: 'ok-$i'),
          item(id: 'low-1', severity: 'low', notes: null),
          item(id: 'med-1', severity: 'medium', notes: null),
        ]),
      ];

      expect(
        SubmitValidator.validate(areas: areas, isAdhoc: false),
        isEmpty,
      );
    });

    test('several independent problems produce one blocker each', () {
      final areas = [
        area([
          item(
            id: 'high-1',
            severity: 'high',
            notes: '',
            photoPaths: const [validPhotoUrl],
          ),
          item(
            id: 'crit-1',
            severity: 'critical',
            notes: 'ok',
            photoPaths: const [validPhotoUrl],
          ),
        ]),
      ];
      final blockers = SubmitValidator.validate(areas: areas, isAdhoc: false);
      final titles = blockers.map((b) => b.title).toList();

      expect(titles, contains('Not enough checks completed'));
      expect(titles, contains('Notes missing'));
      expect(titles, contains('Service not selected'));
    });
  });

  group('isValidPublicUrl', () {
    test('accepts a public Supabase storage URL', () {
      expect(SubmitValidator.isValidPublicUrl(validPhotoUrl), isTrue);
    });

    test('rejects http, other hosts, and non-public paths', () {
      expect(
        SubmitValidator.isValidPublicUrl(
          validPhotoUrl.replaceFirst('https', 'http'),
        ),
        isFalse,
      );
      expect(
        SubmitValidator.isValidPublicUrl(
          'https://other.supabase.co/storage/v1/object/public/x.jpg',
        ),
        isFalse,
      );
      expect(
        SubmitValidator.isValidPublicUrl(
          'https://egalrsutygdvdmjkvduh.supabase.co/storage/v1/object/sign/x',
        ),
        isFalse,
      );
    });
  });
}
