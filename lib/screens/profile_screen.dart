import 'package:flutter/material.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../services/inspection_draft_storage.dart';
import '../services/inspection_session.dart';
import '../services/report_history_service.dart';
import '../services/sync_status.dart';
import '../widgets/app_card.dart';
import '../widgets/app_common.dart';
import '../widgets/app_sliver_bar.dart';
import '../widgets/badge.dart';
import 'signin_screen.dart';

/// Tab 4 — who is signed in, what the current inspection is, and sign out.
///
/// Report history moved to the Reports tab; this screen no longer tries to be
/// both an identity page and a history page.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = InspectionSession.inspectorName ?? 'Inspector';

    return CustomScrollView(
      slivers: [
        const AppSliverBar(title: 'Me', subtitle: 'Inspector profile'),
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
                  AppSpacing.xxxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildIdentityCard(name),
                    const SizedBox(height: AppSpacing.lg),
                    _buildDetailsCard(),
                    const SizedBox(height: AppSpacing.lg),
                    if (InspectionSession.isActive) ...[
                      _buildCurrentInspectionCard(),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    _buildSyncCard(),
                    const SizedBox(height: AppSpacing.xxl),
                    OutlinedButton.icon(
                      onPressed: () => _confirmLogout(context),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        minimumSize: const Size.fromHeight(
                          AppSizes.minTapTarget,
                        ),
                        side: const BorderSide(color: AppColors.neutral200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityCard(String name) {
    return AppCard(
      elevation: AppElevation.raised,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.coral,
            child: Text(
              InspectorAvatar.initialsOf(name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            textAlign: TextAlign.center,
            style: AppStyles.headlineMd.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const AppBadge(label: 'Signed in', variant: BadgeVariant.success),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Inspector details'),
          const SizedBox(height: AppSpacing.md),
          _detail('Inspector ID', InspectionSession.inspectorId ?? '-'),
          _detail('Mobile number', InspectionSession.mobileNumber ?? '-'),
          _detail('Last login', _lastLoginText(), isLast: true),
        ],
      ),
    );
  }

  Widget _buildCurrentInspectionCard() {
    final mode = InspectionSession.inspectionMode ?? 'flat';
    final scopeLabel = mode == 'society'
        ? 'Scope'
        : mode == 'individual'
            ? 'Owner'
            : 'Flat / Block';

    return AppCard(
      accentColor: AppColors.coral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Current inspection'),
          const SizedBox(height: AppSpacing.md),
          _detail('Property', InspectionSession.societyName ?? '-'),
          _detail('Type', '${inspectionTypeLabel(mode)} inspection'),
          _detail(scopeLabel, InspectionSession.flatNumber ?? '-'),
          _detail(
            'Inspection code',
            InspectionSession.inspectionCode ?? InspectionSession.keprId ?? '-',
          ),
          _detail(
            'Inspection ID',
            InspectionSession.inspectionId ?? '-',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Connection'),
          const SizedBox(height: AppSpacing.md),
          ValueListenableBuilder<bool>(
            valueListenable: SyncStatus.instance.isOnline,
            builder: (context, online, _) {
              return Row(
                children: [
                  Icon(
                    online ? Icons.cloud_done_outlined : Icons.cloud_off,
                    size: 18,
                    color: online ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      online
                          ? 'Online — drafts sync to the server.'
                          : 'Offline — drafts are saved on this device only.',
                      style: AppStyles.bodySm.copyWith(
                        color: AppColors.neutral700,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          ValueListenableBuilder<DateTime?>(
            valueListenable: SyncStatus.instance.lastSavedAt,
            builder: (context, _, __) {
              return Text(
                SyncStatus.instance.describeLastSaved(),
                style: AppStyles.labelSm.copyWith(
                  color: AppColors.neutral600,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: AppStyles.labelSm.copyWith(color: AppColors.neutral600),
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

  String _lastLoginText() {
    final value = InspectionSession.lastLoginAt;
    if (value == null) return '-';
    return formatReportDateTime(value);
  }

  /// Signing out clears the draft, so it must be confirmed. Previously this
  /// was a single unguarded tap.
  Future<void> _confirmLogout(BuildContext context) async {
    final hasActiveWork = InspectionSession.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: Text(
          hasActiveWork
              ? 'You have an inspection in progress. Signing out clears the '
                  'draft on this device. Submitted reports are not affected.'
              : 'You will need your mobile number and password to sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    InspectionSession.clear();
    await InspectionDraftStorage.clearAll();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }
}
