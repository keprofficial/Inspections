import 'package:flutter/material.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import 'kepr_button.dart';

/// A section heading with an optional trailing action.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget? trailing;

  const AppSectionHeader({
    Key? key,
    required this.title,
    this.caption,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppStyles.headlineMd.copyWith(
                  color: AppColors.navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  style: AppStyles.bodySm.copyWith(color: AppColors.neutral600),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Shown instead of a blank screen whenever a list has nothing in it.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.coral.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.coral),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppStyles.headlineMd.copyWith(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppStyles.bodyMd.copyWith(color: AppColors.neutral600),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              KeprButton(label: actionLabel, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single number plus its label. Used for the Home "this week" strip.
class AppStatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const AppStatTile({
    Key? key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.headlineMd.copyWith(
              color: AppColors.navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.labelSm.copyWith(color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }
}

/// A horizontal progress bar with a consistent look across the app.
class AppProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;

  const AppProgressBar({
    Key? key,
    required this.value,
    this.color,
    this.height = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: AppColors.neutral200,
        valueColor: AlwaysStoppedAnimation(color ?? AppColors.coral),
      ),
    );
  }
}

/// A selectable filter chip used by the Inspect and Reports tabs.
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  const AppFilterChip({
    Key? key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.coral : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Container(
            constraints: const BoxConstraints(minHeight: 38),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: selected ? AppColors.coral : AppColors.neutral200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppStyles.labelSm.copyWith(
                    fontSize: 13,
                    color: selected ? Colors.white : AppColors.neutral700,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                if (count != null && count! > 0) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '$count',
                    style: AppStyles.labelSm.copyWith(
                      fontSize: 13,
                      color: selected
                          ? Colors.white.withOpacity(0.85)
                          : AppColors.neutral500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
