import 'package:flutter/material.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../models/models.dart';
import '../services/inspection_session.dart';
import '../services/inspection_submit_service.dart';
import '../widgets/app_card.dart';
import '../widgets/kepr_button.dart';
import 'home_screen.dart' show openReportUrl;

/// The full-screen submit experience.
///
/// Replaces the old ending — a spinner, a SnackBar, then
/// `pushReplacement(SignInScreen)`, which dropped the inspector on what looked
/// like a login page with no way to reach the PDF they had just produced.
class SubmitResultScreen extends StatefulWidget {
  final List<InspectionArea> areas;

  const SubmitResultScreen({Key? key, required this.areas}) : super(key: key);

  @override
  State<SubmitResultScreen> createState() => _SubmitResultScreenState();
}

class _SubmitResultScreenState extends State<SubmitResultScreen> {
  SubmitStep _step = SubmitStep.generatingPdf;
  SubmitOutcome? _outcome;
  bool _running = true;

  /// Captured property details, because a successful submit clears the session.
  late String _propertyName;
  late String _propertyScope;

  @override
  void initState() {
    super.initState();
    _propertyName = InspectionSession.societyName ?? 'Property';
    _propertyScope = InspectionSession.flatNumber ?? '-';
    _run();
  }

  Future<void> _run({String? cachedReportUrl}) async {
    setState(() {
      _running = true;
      _outcome = null;
      _step = cachedReportUrl == null
          ? SubmitStep.generatingPdf
          : SubmitStep.savingReport;
    });

    final outcome = await InspectionSubmitService.instance.submit(
      areas: widget.areas,
      cachedReportUrl: cachedReportUrl,
      onStep: (step) {
        if (mounted) setState(() => _step = step);
      },
    );

    if (!mounted) return;
    setState(() {
      _outcome = outcome;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final outcome = _outcome;
    return PopScope(
      // Leaving mid-upload would strand the report. Only allow exit once the
      // run has settled one way or the other.
      canPop: !_running,
      child: Scaffold(
        backgroundColor: AppColors.neutral50,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.formMaxWidth,
                ),
                child: outcome == null
                    ? _buildProgress()
                    : outcome.success
                        ? _buildSuccess(outcome)
                        : _buildFailure(outcome),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Submitting inspection',
          textAlign: TextAlign.center,
          style: AppStyles.headlineMd.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Keep this tab open until it finishes.',
          textAlign: TextAlign.center,
          style: AppStyles.bodySm.copyWith(color: AppColors.neutral600),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppCard(
          elevation: AppElevation.raised,
          child: Column(
            children: [
              _stepRow(SubmitStep.generatingPdf, 'Generating PDF'),
              const SizedBox(height: AppSpacing.lg),
              _stepRow(SubmitStep.uploadingPdf, 'Uploading report'),
              const SizedBox(height: AppSpacing.lg),
              _stepRow(SubmitStep.savingReport, 'Saving to KEPR'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepRow(SubmitStep step, String label) {
    final isDone = step.index < _step.index;
    final isActive = step == _step;
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: isDone
              ? const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 22,
                )
              : isActive
                  ? const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(AppColors.coral),
                    )
                  : const Icon(
                      Icons.radio_button_unchecked,
                      color: AppColors.neutral300,
                      size: 22,
                    ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: AppStyles.bodyMd.copyWith(
              color: isDone || isActive ? AppColors.navy : AppColors.neutral500,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(SubmitOutcome outcome) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: 38,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Report submitted',
          textAlign: TextAlign.center,
          style: AppStyles.headlineMd.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$_propertyName · $_propertyScope',
          textAlign: TextAlign.center,
          style: AppStyles.bodyMd.copyWith(color: AppColors.neutral600),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppCard(
          child: Column(
            children: [
              if (outcome.inspectionCode != null)
                _summaryRow('Inspection code', outcome.inspectionCode!),
              if (outcome.healthScore != null)
                _summaryRow('Health score', '${outcome.healthScore}'),
              if (outcome.criticalIssueRows != null)
                _summaryRow(
                  'Critical service rows',
                  '${outcome.criticalIssueRows}',
                  isLast: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        KeprButton(
          label: 'View report PDF',
          height: AppSizes.minTapTarget,
          icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
          onPressed: () => openReportUrl(context, outcome.reportUrl ?? ''),
        ),
        const SizedBox(height: AppSpacing.md),
        KeprButton(
          label: 'Done',
          height: AppSizes.minTapTarget,
          variant: ButtonVariant.secondary,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppStyles.bodySm.copyWith(color: AppColors.neutral600),
            ),
          ),
          Text(
            value,
            style: AppStyles.labelMd.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailure(SubmitOutcome outcome) {
    final canResume = outcome.reportUrl != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.priority_high_rounded,
            color: AppColors.error,
            size: 36,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Submit did not finish',
          textAlign: TextAlign.center,
          style: AppStyles.headlineMd.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your inspection is still saved. Nothing was lost.',
          textAlign: TextAlign.center,
          style: AppStyles.bodySm.copyWith(color: AppColors.neutral600),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          accentColor: AppColors.error,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Failed at: ${_stepLabel(outcome.failedStep)}',
                style: AppStyles.labelMd.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                outcome.errorMessage ?? 'Unknown error.',
                style: AppStyles.bodySm.copyWith(color: AppColors.neutral700),
              ),
              if (canResume) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'The PDF was already uploaded — retrying will only redo the '
                  'database step.',
                  style: AppStyles.labelSm.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        KeprButton(
          label: canResume ? 'Retry saving report' : 'Retry submit',
          height: AppSizes.minTapTarget,
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => _run(cachedReportUrl: outcome.reportUrl),
        ),
        const SizedBox(height: AppSpacing.md),
        KeprButton(
          label: 'Back to inspection',
          height: AppSizes.minTapTarget,
          variant: ButtonVariant.secondary,
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    );
  }

  String _stepLabel(SubmitStep step) {
    switch (step) {
      case SubmitStep.generatingPdf:
        return 'generating the PDF';
      case SubmitStep.uploadingPdf:
        return 'uploading the report';
      case SubmitStep.savingReport:
        return 'saving to KEPR';
      case SubmitStep.done:
        return 'finishing';
    }
  }
}
