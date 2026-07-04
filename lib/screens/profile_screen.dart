import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../services/inspection_draft_storage.dart';
import '../services/inspection_session.dart';
import '../services/supabase_repository.dart';
import '../widgets/badge.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/kepr_header.dart';
import 'signin_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Function(BottomNavTab)? onTabChange;

  const ProfileScreen({Key? key, this.onTabChange}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = InspectionSession.inspectorName ?? 'Inspector';
    final initials = _initials(name);
    final inspectionType = InspectionSession.inspectionMode ?? 'flat';
    final scopeLabel = inspectionType == 'society'
        ? 'Scope'
        : inspectionType == 'individual'
            ? 'Owner'
            : 'Flat / Block';

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: KeprHeader(
        title: 'Profile',
        subtitle: name,
        onLogoTap: () => onTabChange?.call(BottomNavTab.home),
        onNotificationTap: () => _showLastLogin(context),
        onMenuTap: () => onTabChange?.call(BottomNavTab.home),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.neutral200),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.coral,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style: AppStyles.headlineMd.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const AppBadge(
                        label: 'Logged In',
                        variant: BadgeVariant.success,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  title: 'Inspector Details',
                  children: [
                    _detail(
                        'Inspector ID', InspectionSession.inspectorId ?? '-'),
                    _detail(
                        'Mobile Number', InspectionSession.mobileNumber ?? '-'),
                    _detail('Last Login', _lastLoginText()),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<SubmittedInspectionReport>>(
                  future: _loadReportHistory(),
                  builder: (context, snapshot) {
                    final reports = snapshot.data ?? const [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _section(
                          title: 'Current Inspection',
                          children: [
                            _detail('Society',
                                InspectionSession.societyName ?? '-'),
                            _detail('Inspection Type',
                                _inspectionTypeLabel(inspectionType)),
                            _detail(scopeLabel, InspectionSession.flatNumber ?? '-'),
                            _detail(
                              'Inspection Code',
                              InspectionSession.inspectionCode ??
                                  InspectionSession.keprId ??
                                  '-',
                            ),
                            _detail('Inspection ID',
                                InspectionSession.inspectionId ?? '-'),
                            const SizedBox(height: 4),
                            Text(
                              'Last 3 Reports',
                              style: AppStyles.labelSm.copyWith(
                                color: AppColors.neutral500,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (reports.isEmpty)
                              Text(
                                'No uploaded reports found yet.',
                                style: AppStyles.bodySm.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              )
                            else
                              for (final report in reports.take(3))
                                _submittedReportTile(context, report,
                                    compact: true),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _section(
                          title: 'Inspections Done',
                          children: reports.isEmpty
                              ? [
                                  Text(
                                    'No submitted reports yet.',
                                    style: AppStyles.bodySm.copyWith(
                                      color: AppColors.neutral500,
                                    ),
                                  ),
                                ]
                              : [
                                  for (final report in reports)
                                    _submittedReportTile(context, report),
                                ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    InspectionSession.clear();
                    await InspectionDraftStorage.clearAll();
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              activeTab: BottomNavTab.profile,
              onTabChange: (tab) {
                if (tab != BottomNavTab.profile) {
                  onTabChange?.call(tab);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStyles.labelMd.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppStyles.labelSm.copyWith(color: AppColors.neutral500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodySm.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submittedReportTile(
      BuildContext context, SubmittedInspectionReport report,
      {bool compact = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.societyName,
            style: AppStyles.labelMd.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${report.flatNumber}'
            '${report.propertyCode == null ? '' : ' / ${report.propertyCode}'}',
            style: AppStyles.bodySm.copyWith(color: AppColors.neutral600),
          ),
          const SizedBox(height: 4),
          Text(
            _dateTimeText(report.submittedAt),
            style: AppStyles.labelSm.copyWith(color: AppColors.neutral500),
          ),
          SizedBox(height: compact ? 4 : 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _openReport(context, report.reportUrl),
              icon: const Icon(Icons.download),
              label: Text(compact ? 'Download' : 'Download Report'),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<SubmittedInspectionReport>> _loadReportHistory() async {
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
    return reports.where(_matchesCurrentInspectionContext).toList();
  }

  bool _matchesCurrentInspectionContext(SubmittedInspectionReport report) {
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

  Future<void> _openReport(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open report: $url')),
      );
    }
  }

  void _showLastLogin(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: Text('Last login: ${_lastLoginText()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _lastLoginText() {
    final value = InspectionSession.lastLoginAt;
    if (value == null) return '-';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String _dateTimeText(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String _inspectionTypeLabel(String value) {
    switch (value) {
      case 'society':
        return 'Society Inspection';
      case 'individual':
        return 'Individual Home Inspection';
      default:
        return 'Flat Inspection';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'I';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}
