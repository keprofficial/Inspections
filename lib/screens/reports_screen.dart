import 'package:flutter/material.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../services/inspection_draft_storage.dart';
import '../services/report_history_service.dart';
import '../widgets/app_card.dart';
import '../widgets/app_common.dart';
import '../widgets/app_sliver_bar.dart';
import 'home_screen.dart' show openReportUrl;

/// Tab 3 — submitted report history.
///
/// Promoted out of Profile, where it was buried under inspector details.
/// Sources both `inspections.full_report_pdf_url` and
/// `individual_inspections.report_pdf_url` via [ReportHistoryService].
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<SubmittedInspectionReport>> _future;
  final TextEditingController _searchController = TextEditingController();
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _future = ReportHistoryService.instance.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = ReportHistoryService.instance.load();
    setState(() => _future = future);
    await future;
  }

  List<SubmittedInspectionReport> _filter(
    List<SubmittedInspectionReport> reports,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    return reports.where((report) {
      if (_typeFilter != 'all' &&
          (report.inspectionType ?? '') != _typeFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return report.societyName.toLowerCase().contains(query) ||
          report.flatNumber.toLowerCase().contains(query) ||
          (report.propertyCode ?? '').toLowerCase().contains(query);
    }).toList(growable: false);
  }

  /// Groups reports under a "Month Year" heading, newest first.
  Map<String, List<SubmittedInspectionReport>> _groupByMonth(
    List<SubmittedInspectionReport> reports,
  ) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final grouped = <String, List<SubmittedInspectionReport>>{};
    for (final report in reports) {
      final key = '${monthNames[report.submittedAt.month - 1]} '
          '${report.submittedAt.year}';
      grouped.putIfAbsent(key, () => []).add(report);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<SubmittedInspectionReport>>(
        future: _future,
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <SubmittedInspectionReport>[];
          final visible = _filter(all);
          final grouped = _groupByMonth(visible);

          return CustomScrollView(
            slivers: [
              const AppSliverBar(
                title: 'Reports',
                subtitle: 'Submitted inspection reports',
              ),
              SliverToBoxAdapter(child: _buildControls(all)),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: all.isEmpty
                        ? Icons.description_outlined
                        : Icons.search_off,
                    title: all.isEmpty
                        ? 'No reports yet'
                        : 'Nothing matches that filter',
                    message: all.isEmpty
                        ? 'Finish and submit an inspection and its report '
                            'will appear here.'
                        : 'Try a different search term or filter.',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildListDelegate([
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSizes.contentMaxWidth,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.xxl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final entry in grouped.entries) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.xs,
                                    AppSpacing.lg,
                                    0,
                                    AppSpacing.sm,
                                  ),
                                  child: Text(
                                    '${entry.key}  ·  ${entry.value.length}',
                                    style: AppStyles.labelSm.copyWith(
                                      color: AppColors.neutral600,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                for (final report in entry.value) ...[
                                  _ReportRow(report: report),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControls(List<SubmittedInspectionReport> all) {
    int countOf(String type) =>
        all.where((report) => (report.inspectionType ?? '') == type).length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: AppStyles.buildInputDecoration(
                  hint: 'Search property, flat, or code',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AppFilterChip(
                      label: 'All',
                      count: all.length,
                      selected: _typeFilter == 'all',
                      onTap: () => setState(() => _typeFilter = 'all'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppFilterChip(
                      label: 'Flat',
                      count: countOf('flat'),
                      selected: _typeFilter == 'flat',
                      onTap: () => setState(() => _typeFilter = 'flat'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppFilterChip(
                      label: 'Society',
                      count: countOf('society'),
                      selected: _typeFilter == 'society',
                      onTap: () => setState(() => _typeFilter = 'society'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppFilterChip(
                      label: 'Individual',
                      count: countOf('individual'),
                      selected: _typeFilter == 'individual',
                      onTap: () => setState(() => _typeFilter = 'individual'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final SubmittedInspectionReport report;

  const _ReportRow({required this.report});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => openReportUrl(context, report.reportUrl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.coral.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.coral,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  report.societyName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.labelMd.copyWith(
                    fontSize: 15,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  report.flatNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bodySm.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Tag(label: inspectionTypeLabel(report.inspectionType)),
                    if (report.propertyCode != null)
                      _Tag(label: report.propertyCode!),
                    Text(
                      formatReportDateTime(report.submittedAt),
                      style: AppStyles.labelSm.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.download_outlined, color: AppColors.neutral400),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppStyles.labelSm.copyWith(
          color: AppColors.neutral700,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
