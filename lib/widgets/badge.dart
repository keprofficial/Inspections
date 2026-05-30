import 'package:flutter/material.dart';
import '../constants/colors.dart';

enum BadgeVariant { default_, success, warning, error, info, urgent }

class AppBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;

  const AppBadge({
    Key? key,
    required this.label,
    this.variant = BadgeVariant.default_,
  }) : super(key: key);

  Color get backgroundColor {
    switch (variant) {
      case BadgeVariant.success:
        return const Color(0xFF10B981).withOpacity(0.1);
      case BadgeVariant.warning:
        return const Color(0xFFF59E0B).withOpacity(0.1);
      case BadgeVariant.error:
        return const Color(0xFFEF4444).withOpacity(0.1);
      case BadgeVariant.info:
        return const Color(0xFF3B82F6).withOpacity(0.1);
      case BadgeVariant.urgent:
        return const Color(0xFFEF4444).withOpacity(0.1);
      default:
        return AppColors.neutral100;
    }
  }

  Color get textColor {
    switch (variant) {
      case BadgeVariant.success:
        return const Color(0xFF10B981);
      case BadgeVariant.warning:
        return const Color(0xFFF59E0B);
      case BadgeVariant.error:
        return const Color(0xFFEF4444);
      case BadgeVariant.info:
        return const Color(0xFF3B82F6);
      case BadgeVariant.urgent:
        return AppColors.coral;
      default:
        return AppColors.neutral700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
