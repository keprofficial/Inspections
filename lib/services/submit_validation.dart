import '../config/supabase_config.dart';
import '../constants/severity.dart';
import '../models/models.dart';

/// A single reason the inspection cannot be submitted yet, with the items it
/// applies to so the UI can offer a "Fix →" deep link.
class SubmitBlocker {
  final String title;
  final String detail;
  final List<BlockerTarget> targets;

  const SubmitBlocker({
    required this.title,
    required this.detail,
    this.targets = const [],
  });

  /// The message previously surfaced by `throw Exception(...)`, preserved so
  /// nothing is lost when a blocker is reported as text.
  String get message => targets.isEmpty
      ? detail
      : '$detail: ${targets.take(3).map((t) => t.itemName).join(', ')}';
}

class BlockerTarget {
  final String areaId;
  final String itemId;
  final String itemName;

  const BlockerTarget({
    required this.areaId,
    required this.itemId,
    required this.itemName,
  });
}

/// Validates an inspection for final submit.
///
/// Replaces the six `throw Exception(...)` paths in the dashboard, which all
/// funnelled into one transient SnackBar after the work was already done. The
/// rules and their wording are unchanged — only their delivery is.
class SubmitValidator {
  SubmitValidator._();

  /// Photos must be public HTTPS URLs on the configured Supabase project.
  static bool isValidPublicUrl(String value) {
    final uri = Uri.tryParse(value);
    final expectedHost = Uri.tryParse(SupabaseConfig.url)?.host;
    return uri != null &&
        uri.scheme == 'https' &&
        uri.path.isNotEmpty &&
        expectedHost != null &&
        uri.host == expectedHost &&
        uri.path.contains('/storage/v1/object/public/');
  }

  static List<InspectionItem> _allItems(List<InspectionArea> areas) {
    return areas.expand((area) => area.items).toList(growable: false);
  }

  static BlockerTarget _targetFor(InspectionArea area, InspectionItem item) {
    return BlockerTarget(
      areaId: area.id,
      itemId: item.id,
      itemName: item.name,
    );
  }

  /// Every reason this inspection cannot be submitted, most blocking first.
  /// An empty list means submit is allowed.
  static List<SubmitBlocker> validate({
    required List<InspectionArea> areas,
    required bool isAdhoc,
  }) {
    final blockers = <SubmitBlocker>[];
    final items = _allItems(areas);
    final completedCount = items.where((item) => item.completed).length;

    // 1. Ad-hoc plans build their own checklist and must contain something.
    if (isAdhoc && items.isEmpty) {
      blockers.add(
        const SubmitBlocker(
          title: 'No checks added',
          detail: 'Add at least one custom inspection check first.',
        ),
      );
    }

    // 2. Standard plans require a minimum amount of work. Deliberately not
    //    applied to ad-hoc plans.
    if (!isAdhoc && completedCount < 5) {
      blockers.add(
        SubmitBlocker(
          title: 'Not enough checks completed',
          detail: 'Complete at least 5 inspection checks before submitting. '
              'Current completed checks: $completedCount.',
        ),
      );
    }

    // 3. Photos that are not public Supabase URLs would break the report.
    final invalidPhotoTargets = <BlockerTarget>[];
    for (final area in areas) {
      for (final item in area.items) {
        final hasInvalid = item.photoPaths.any((url) => !isValidPublicUrl(url));
        if (hasInvalid) invalidPhotoTargets.add(_targetFor(area, item));
      }
    }
    if (invalidPhotoTargets.isNotEmpty) {
      blockers.add(
        SubmitBlocker(
          title: 'Invalid photo link',
          detail: 'Invalid photo URL found. Please recapture/upload before '
              'submit',
          targets: invalidPhotoTargets,
        ),
      );
    }

    // 4. High and critical findings need technician notes.
    final missingNotesTargets = <BlockerTarget>[];
    for (final area in areas) {
      for (final item in area.items) {
        final severity = Severity.fromValue(item.severity);
        if (item.completed &&
            severity != null &&
            severity.requiresNotes &&
            (item.notes ?? '').trim().isEmpty) {
          missingNotesTargets.add(_targetFor(area, item));
        }
      }
    }
    if (missingNotesTargets.isNotEmpty) {
      blockers.add(
        SubmitBlocker(
          title: 'Notes missing',
          detail: 'Technician notes are required for high and critical issues',
          targets: missingNotesTargets,
        ),
      );
    }

    // 5. Critical photos captured on device but never uploaded.
    final notUploadedTargets = <BlockerTarget>[];
    for (final area in areas) {
      for (final item in area.items) {
        final severity = Severity.fromValue(item.severity);
        if (item.completed &&
            severity == Severity.critical &&
            item.photoEvidenceBase64.isNotEmpty &&
            item.photoPaths.isEmpty) {
          notUploadedTargets.add(_targetFor(area, item));
        }
      }
    }
    if (notUploadedTargets.isNotEmpty) {
      blockers.add(
        SubmitBlocker(
          title: 'Photos not uploaded',
          detail: 'Some critical issue photos are saved locally but not '
              'uploaded. Please recapture/upload before final submit',
          targets: notUploadedTargets,
        ),
      );
    }

    // 6. Critical findings must carry a service.
    final missingServiceTargets = <BlockerTarget>[];
    for (final area in areas) {
      for (final item in area.items) {
        final severity = Severity.fromValue(item.severity);
        if (item.completed &&
            severity == Severity.critical &&
            item.selectedServices.isEmpty) {
          missingServiceTargets.add(_targetFor(area, item));
        }
      }
    }
    if (missingServiceTargets.isNotEmpty) {
      blockers.add(
        SubmitBlocker(
          title: 'Service not selected',
          detail: 'Services not added. Select a service for each critical '
              'issue or add Consultation for Rs 150',
          targets: missingServiceTargets,
        ),
      );
    }

    return blockers;
  }
}
