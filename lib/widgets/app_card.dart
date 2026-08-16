import 'package:flutter/material.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';

/// Surface elevation levels. Only one [AppElevation.floating] element should
/// appear per screen — the thing the user is meant to act on.
enum AppElevation { flat, raised, floating }

/// The standard content surface. Replaces the ad-hoc
/// `Container(decoration: BoxDecoration(color: white, radius 8, border, shadowSm))`
/// repeated across every screen.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final AppElevation elevation;
  final VoidCallback? onTap;

  /// Draws a 4px vertical rail on the leading edge. Used to flag a card as
  /// critical or as the primary action without changing its whole border.
  final Color? accentColor;
  final Color? background;
  final Color? borderColor;
  final double radius;

  const AppCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.elevation = AppElevation.flat,
    this.onTap,
    this.accentColor,
    this.background,
    this.borderColor,
    this.radius = AppRadii.md,
  }) : super(key: key);

  List<BoxShadow> get _shadow {
    switch (elevation) {
      case AppElevation.flat:
        return const [];
      case AppElevation.raised:
        return AppColors.shadowSm;
      case AppElevation.floating:
        return AppColors.shadowMd;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = accentColor;
    Widget content = Padding(padding: padding, child: child);

    if (accent != null) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4, color: accent),
          Expanded(child: content),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: background ?? Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ??
              (accent == null ? AppColors.neutral200 : accent.withOpacity(0.4)),
        ),
        boxShadow: _shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap, child: content),
            ),
    );
  }
}
