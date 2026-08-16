import 'inspection_draft_storage.dart';
import 'inspection_session.dart';
import 'supabase_repository.dart';

/// Loads submitted-report history for the signed-in inspector.
///
/// Cross-device visibility comes from the database — `inspections`
/// (`full_report_pdf_url`) and `individual_inspections` (`report_pdf_url`).
/// The local SharedPreferences cache is merged in as a convenience only, so a
/// report submitted on this device shows immediately, but it is never treated
/// as the source of truth for cross-device history.
class ReportHistoryService {
  ReportHistoryService._();

  static final ReportHistoryService instance = ReportHistoryService._();

  Future<List<SubmittedInspectionReport>> load() async {
    final remote =
        await SupabaseRepository.instance.fetchSubmittedInspectionReports(
      inspectorId: InspectionSession.inspectorId,
      inspectorName: InspectionSession.inspectorName,
      inspectorMobile: InspectionSession.mobileNumber,
    );
    final local = await InspectionDraftStorage.loadSubmittedReports();

    final byId = <String, SubmittedInspectionReport>{};
    for (final report in [...remote, ...local]) {
      final key =
          report.inspectionId.isEmpty ? report.reportUrl : report.inspectionId;
      byId[key] = report;
    }
    final reports = byId.values.toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return reports;
  }

  /// True when a report belongs to the inspection currently in the session.
  bool matchesCurrentInspection(SubmittedInspectionReport report) {
    final currentType = InspectionSession.inspectionMode;
    if (currentType == null || currentType.isEmpty) return true;

    if ((report.inspectionType ?? '').isNotEmpty &&
        report.inspectionType != currentType) {
      return false;
    }

    final currentPropertyId = InspectionSession.propertyId;
    if (currentType != 'individual' &&
        currentPropertyId != null &&
        currentPropertyId.isNotEmpty &&
        (report.propertyId ?? '').isNotEmpty) {
      return report.propertyId == currentPropertyId;
    }

    return true;
  }

  /// Counts for the Home "this week" strip.
  ReportSummary summarize(List<SubmittedInspectionReport> reports) {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final thisWeek = reports
        .where((report) => !report.submittedAt.isBefore(weekStart))
        .toList(growable: false);
    return ReportSummary(
      thisWeekCount: thisWeek.length,
      totalCount: reports.length,
      lastSubmittedAt: reports.isEmpty ? null : reports.first.submittedAt,
    );
  }
}

class ReportSummary {
  final int thisWeekCount;
  final int totalCount;
  final DateTime? lastSubmittedAt;

  const ReportSummary({
    required this.thisWeekCount,
    required this.totalCount,
    this.lastSubmittedAt,
  });
}

/// Shared formatting so a date never renders three different ways.
String formatReportDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

String formatReportDateTime(DateTime value) {
  return '${formatReportDate(value)} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

String inspectionTypeLabel(String? value) {
  switch (value) {
    case 'society':
      return 'Society';
    case 'individual':
      return 'Individual';
    case 'flat':
      return 'Flat';
    default:
      return 'Inspection';
  }
}
