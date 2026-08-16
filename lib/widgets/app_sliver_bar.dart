import 'package:flutter/material.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../services/inspection_session.dart';
import 'kepr_logo.dart';
import 'sync_indicator.dart';

/// The standard branded top bar for a tab body.
///
/// Every icon-only action carries a semantics label — the old header's bell
/// and tune buttons had none.
class AppSliverBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showLogo;
  final bool floating;
  final List<Widget> actions;

  const AppSliverBar({
    Key? key,
    required this.title,
    this.subtitle,
    this.showLogo = true,
    this.floating = true,
    this.actions = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.coral,
      foregroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      floating: floating,
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.lg,
      title: Row(
        children: [
          if (showLogo) ...[
            const KeprLogo(size: 34),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.labelSm.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        const SyncStatusDot(),
        ...actions,
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}

/// The inspector's initials avatar, used as the Profile affordance.
class InspectorAvatar extends StatelessWidget {
  final VoidCallback? onTap;
  final double radius;

  const InspectorAvatar({Key? key, this.onTap, this.radius = 17})
      : super(key: key);

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'IN';
    if (parts.length == 1) {
      final single = parts.first;
      return single.length == 1
          ? single.toUpperCase()
          : single.substring(0, 2).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = InspectionSession.inspectorName ?? 'Inspector';
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.coral,
      child: Text(
        initialsOf(name),
        style: TextStyle(
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w800,
          color: AppColors.coral,
        ),
      ),
    );

    if (onTap == null) return avatar;
    return IconButton(
      onPressed: onTap,
      tooltip: 'Profile',
      icon: avatar,
    );
  }
}
