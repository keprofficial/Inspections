import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../services/inspection_draft_storage.dart';
import '../services/inspection_session.dart';
import '../services/report_history_service.dart';
import '../services/supabase_repository.dart';
import '../widgets/app_card.dart';
import '../widgets/app_common.dart';
import '../widgets/app_sliver_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/kepr_button.dart';
import 'app_shell.dart';
import 'start_inspection_flow.dart';

/// Tab 1 — the inspector's home.
///
/// Answers "what should I do next?" in one screen: resume what is running,
/// start something new, and see recent output.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<SubmittedInspectionReport>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = ReportHistoryService.instance.load();
  }

  Future<void> _refresh() async {
    final future = ReportHistoryService.instance.load();
    setState(() => _reportsFuture = future);
    await future;
  }

  String get _dayPeriod {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  void _startInspection() {
    final inspector = InspectorLogin(
      userId: InspectionSession.inspectorId,
      displayName: InspectionSession.inspectorName ?? 'Inspector',
      phone: InspectionSession.mobileNumber,
      authToken: InspectionSession.authToken,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StartInspectionFlow(
          inspector: inspector,
          onStarted: () {
            AppShell.of(context)
              ?..refreshData()
              ..goToTab(AppTab.inspect);
          },
          onSessionExpired: () async {
            await InspectionDraftStorage.saveSession();
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = InspectionSession.inspectorName ?? 'Inspector';
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          AppSliverBar(
            title: 'Kepr Inspections',
            subtitle: name,
            actions: [
              InspectorAvatar(
                onTap: () => AppShell.of(context)?.goToTab(AppTab.profile),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.contentMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Good $_dayPeriod, $name',
                        style: AppStyles.headlineMd.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'What would you like to inspect today?',
                        style: AppStyles.bodyMd.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                      if (InspectionSession.isActive) ...[
                        const SizedBox(height: AppSpacing.xl),
                        const _ResumeInspectionCard(),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      KeprButton(
                        label: 'Start new inspection',
                        height: AppSizes.minTapTarget,
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: _startInspection,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      FutureBuilder<List<SubmittedInspectionReport>>(
                        future: _reportsFuture,
                        builder: (context, snapshot) {
                          final reports = snapshot.data ?? const [];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildStatsStrip(reports),
                              const SizedBox(height: AppSpacing.xxl),
                              _buildRecentReports(context, reports, snapshot),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsStrip(List<SubmittedInspectionReport> reports) {
    final summary = ReportHistoryService.instance.summarize(reports);
    return Row(
      children: [
        Expanded(
          child: AppStatTile(
            value: '${summary.thisWeekCount}',
            label: 'Submitted this week',
            icon: Icons.event_available_outlined,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppStatTile(
            value: '${summary.totalCount}',
            label: 'Reports total',
            icon: Icons.description_outlined,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppStatTile(
            value: summary.lastSubmittedAt == null
                ? '—'
                : formatReportDate(summary.lastSubmittedAt!),
            label: 'Last submitted',
            icon: Icons.schedule_outlined,
            color: AppColors.coral,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReports(
    BuildContext context,
    List<SubmittedInspectionReport> reports,
    AsyncSnapshot<List<SubmittedInspectionReport>> snapshot,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: 'Recent reports',
          trailing: TextButton(
            onPressed: () => AppShell.of(context)?.goToTab(AppTab.reports),
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: const Text('See all'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (snapshot.connectionState == ConnectionState.waiting)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (reports.isEmpty)
          AppCard(
            child: Text(
              'No submitted reports yet. Your finished inspections will '
              'appear here.',
              style: AppStyles.bodySm.copyWith(color: AppColors.neutral600),
            ),
          )
        else
          for (final report in reports.take(3)) ...[
            _RecentReportRow(report: report),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

/// The loudest thing on Home when an inspection is running.
class _ResumeInspectionCard extends StatelessWidget {
  const _ResumeInspectionCard();

  @override
  Widget build(BuildContext context) {
    final property = InspectionSession.societyName ??
        InspectionSession.flatNumber ??
        'Active property';
    final mode = inspectionTypeLabel(InspectionSession.inspectionMode);
    final plan = InspectionSession.inspectionPlan ?? 'paid';
    final planLabel = plan == 'adhoc'
        ? 'Ad-hoc'
        : '${plan[0].toUpperCase()}${plan.substring(1)}';

    return AppCard(
      elevation: AppElevation.floating,
      accentColor: AppColors.coral,
      onTap: () => AppShell.of(context)?.goToTab(AppTab.inspect),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.coral.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: AppColors.coral, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'In progress',
                  style: AppStyles.labelSm.copyWith(
                    color: AppColors.coral,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  property,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.labelMd.copyWith(
                    fontSize: 15,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$mode · $planLabel inspection',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.labelSm.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.neutral400),
        ],
      ),
    );
  }
}

class _RecentReportRow extends StatelessWidget {
  final SubmittedInspectionReport report;

  const _RecentReportRow({required this.report});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      onTap: () => openReportUrl(context, report.reportUrl),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  report.societyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.labelMd.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${inspectionTypeLabel(report.inspectionType)} · '
                  '${formatReportDate(report.submittedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.labelSm.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.picture_as_pdf_outlined, color: AppColors.coral),
        ],
      ),
    );
  }
}

/// Opens a report PDF, reporting failure instead of silently doing nothing.
Future<void> openReportUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This report has no downloadable file.')),
    );
    return;
  }
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open report: $url')),
    );
  }
}
