import 'package:flutter/material.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../constants/severity.dart';

/// A compact severity indicator: colour + icon + word, so severity is never
/// communicated by colour alone.
class SeverityPill extends StatelessWidget {
  final Severity severity;
  final bool compact;

  const SeverityPill({
    Key? key,
    required this.severity,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: severity.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: severity.color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(severity.icon, size: compact ? 13 : 15, color: severity.color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            severity.label,
            style: AppStyles.labelSm.copyWith(
              color: severity.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-width selectable severity option used on the checklist item screen.
/// Sized to the 48px minimum tap target and legible at 200% text scale.
class SeverityChoice extends StatelessWidget {
  final Severity severity;
  final bool selected;
  final VoidCallback onTap;

  /// When true the option renders as a prominent full-width row. Used for
  /// [Severity.noIssue], which is the most common answer and is presented
  /// first.
  final bool prominent;

  const SeverityChoice({
    Key? key,
    required this.severity,
    required this.selected,
    required this.onTap,
    this.prominent = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = severity.color;
    return Semantics(
      button: true,
      selected: selected,
      label: '${severity.label} severity',
      child: Material(
        color: selected ? color.withOpacity(0.12) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTapTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(
                color: selected ? color : AppColors.neutral200,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: prominent
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? severity.icon : severity.icon,
                  size: prominent ? 22 : 19,
                  color: selected ? color : AppColors.neutral500,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    severity.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.labelMd.copyWith(
                      fontSize: prominent ? 16 : 14,
                      color: selected ? color : AppColors.neutral700,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
