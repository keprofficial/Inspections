import 'dart:typed_data';

import '../models/models.dart';
import 'inspection_draft_storage.dart';
import 'inspection_session.dart';
import 'report_pdf_service.dart';
import 'submit_validation.dart';
import 'supabase_repository.dart';

/// The stages of a final submit, surfaced to the user instead of one opaque
/// spinner that could run for 30 seconds.
enum SubmitStep { generatingPdf, uploadingPdf, savingReport, done }

class SubmitOutcome {
  final bool success;
  final SubmitStep failedStep;
  final String? errorMessage;

  /// Set once the PDF is uploaded. Retained across a retry so a failure in
  /// the final RPC does not force the inspector to regenerate and re-upload.
  final String? reportUrl;

  final int? healthScore;
  final int? criticalIssueRows;
  final String? inspectionCode;

  const SubmitOutcome({
    required this.success,
    required this.failedStep,
    this.errorMessage,
    this.reportUrl,
    this.healthScore,
    this.criticalIssueRows,
    this.inspectionCode,
  });
}

/// Owns final submission for flat, society, and individual inspections.
///
/// Extracted from the dashboard widget so the sequence — validate, build PDF,
/// upload, persist — is testable and so a retry can resume from the step that
/// actually failed.
class InspectionSubmitService {
  InspectionSubmitService._();

  static final InspectionSubmitService instance = InspectionSubmitService._();

  /// [cachedReportUrl] lets a retry skip PDF generation and upload when those
  /// already succeeded.
  Future<SubmitOutcome> submit({
    required List<InspectionArea> areas,
    required void Function(SubmitStep step) onStep,
    String? cachedReportUrl,
  }) async {
    final blockers = SubmitValidator.validate(
      areas: areas,
      isAdhoc: InspectionSession.isAdhocInspection,
    );
    if (blockers.isNotEmpty) {
      return SubmitOutcome(
        success: false,
        failedStep: SubmitStep.savingReport,
        errorMessage: blockers.first.message,
      );
    }

    final inspectionId = InspectionSession.inspectionId;
    final propertyId = InspectionSession.propertyId;
    if (inspectionId == null || propertyId == null) {
      return const SubmitOutcome(
        success: false,
        failedStep: SubmitStep.savingReport,
        errorMessage: 'Missing selected property. Please select it again.',
      );
    }

    final isIndividual = InspectionSession.isIndividualInspection;
    final inspectionType = isIndividual
        ? 'individual'
        : (InspectionSession.inspectionMode ?? 'flat');
    final propertyName = InspectionSession.societyName ??
        (isIndividual ? 'Individual Property' : 'Property');

    var reportUrl = cachedReportUrl;

    if (reportUrl == null) {
      Uint8List pdfBytes;
      try {
        onStep(SubmitStep.generatingPdf);
        pdfBytes = await ReportPdfService.buildCompleteReport(areas);
      } catch (error) {
        return SubmitOutcome(
          success: false,
          failedStep: SubmitStep.generatingPdf,
          errorMessage: '$error',
        );
      }

      try {
        onStep(SubmitStep.uploadingPdf);
        reportUrl = await SupabaseRepository.instance.uploadInspectionReportPdf(
          bytes: pdfBytes,
          propertyId: propertyId,
          inspectionId: inspectionId,
          inspectionType: inspectionType,
          societyName: propertyName,
        );
        if (reportUrl.isEmpty) {
          throw Exception('Could not upload full inspection PDF.');
        }
        if (!SubmitValidator.isValidPublicUrl(reportUrl)) {
          throw Exception('Generated report URL is invalid.');
        }
      } catch (error) {
        return SubmitOutcome(
          success: false,
          failedStep: SubmitStep.uploadingPdf,
          errorMessage: '$error',
        );
      }
    }

    try {
      onStep(SubmitStep.savingReport);
      if (isIndividual) {
        return await _saveIndividualReport(
          areas: areas,
          inspectionId: inspectionId,
          propertyId: propertyId,
          propertyName: propertyName,
          reportUrl: reportUrl,
        );
      }
      return await _saveNormalReport(
        areas: areas,
        inspectionId: inspectionId,
        propertyId: propertyId,
        propertyName: propertyName,
        reportUrl: reportUrl,
      );
    } catch (error) {
      // The PDF is already uploaded — hand the URL back so a retry resumes
      // from the database write rather than redoing everything.
      return SubmitOutcome(
        success: false,
        failedStep: SubmitStep.savingReport,
        errorMessage: '$error',
        reportUrl: reportUrl,
      );
    }
  }

  Future<SubmitOutcome> _saveNormalReport({
    required List<InspectionArea> areas,
    required String inspectionId,
    required String propertyId,
    required String propertyName,
    required String reportUrl,
  }) async {
    final authToken = InspectionSession.authToken;
    if (authToken == null) {
      throw Exception(
        'Missing inspection session. Please select society, block, and flat '
        'again before final submit.',
      );
    }

    final result = await SupabaseRepository.instance.submitReport(
      propertyId: propertyId,
      inspectionId: inspectionId,
      areas: areas,
      authToken: authToken,
      reportPdfUrl: reportUrl,
    );

    final flatNumber = InspectionSession.flatNumber ?? '-';
    final code = InspectionSession.inspectionCode ?? InspectionSession.keprId;
    await InspectionDraftStorage.saveSubmittedReport(
      SubmittedInspectionReport(
        inspectionId: inspectionId,
        inspectionType: InspectionSession.inspectionMode ?? 'flat',
        propertyId: propertyId,
        societyName: propertyName,
        flatNumber: flatNumber,
        propertyCode: code,
        reportUrl: reportUrl,
        submittedAt: DateTime.now(),
      ),
    );
    await InspectionDraftStorage.clearInspectionDraft();

    return SubmitOutcome(
      success: true,
      failedStep: SubmitStep.done,
      reportUrl: reportUrl,
      healthScore: result?.healthScore,
      criticalIssueRows: result?.criticalIssueRows,
      inspectionCode: code,
    );
  }

  Future<SubmitOutcome> _saveIndividualReport({
    required List<InspectionArea> areas,
    required String inspectionId,
    required String propertyId,
    required String propertyName,
    required String reportUrl,
  }) async {
    final ownerName = InspectionSession.propertyOwnerName ?? '-';
    final ownerMobile = InspectionSession.propertyOwnerMobile ?? '-';

    // Idempotent by inspection_ref, so a retry cannot create a duplicate.
    final savedId =
        await SupabaseRepository.instance.submitIndividualInspection(
      inspectionRef: inspectionId,
      inspectionCode: InspectionSession.inspectionCode ?? inspectionId,
      inspectionType: 'individual',
      areas: areas,
      inspectorName: InspectionSession.inspectorName ?? 'Inspector',
      inspectorId: InspectionSession.inspectorId,
      inspectorMobile: InspectionSession.mobileNumber,
      propertyName: propertyName,
      ownerName: ownerName,
      ownerMobile: ownerMobile,
      reportPdfUrl: reportUrl,
    );

    final code = InspectionSession.inspectionCode ?? savedId;
    await InspectionDraftStorage.saveSubmittedReport(
      SubmittedInspectionReport(
        inspectionId: inspectionId,
        inspectionType: 'individual',
        propertyId: propertyId,
        societyName: propertyName,
        flatNumber: 'Owner: $ownerName',
        propertyCode: code,
        reportUrl: reportUrl,
        submittedAt: DateTime.now(),
      ),
    );
    await InspectionDraftStorage.clearInspectionDraft();

    return SubmitOutcome(
      success: true,
      failedStep: SubmitStep.done,
      reportUrl: reportUrl,
      inspectionCode: code,
    );
  }
}
