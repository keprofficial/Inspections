import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/app_styles.dart';

enum ButtonVariant { primary, secondary, ghost }

class KeprButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final double? width;
  final double height;
  final Widget? icon;
  final bool showArrow;
  final bool isLoading;
  final bool enabled;

  const KeprButton({
    Key? key,
    this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.width,
    this.height = 48,
    this.icon,
    this.showArrow = false,
    this.isLoading = false,
    this.enabled = true,
  }) : super(key: key);

  Color get backgroundColor {
    if (!enabled) return AppColors.neutral200;
    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.coral;
      case ButtonVariant.secondary:
        return Colors.white;
      case ButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color get foregroundColor {
    switch (variant) {
      case ButtonVariant.primary:
        return Colors.white;
      case ButtonVariant.secondary:
        return AppColors.navy;
      case ButtonVariant.ghost:
        return AppColors.coral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled && !isLoading ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              border: variant == ButtonVariant.secondary
                  ? Border.all(color: AppColors.neutral200)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(foregroundColor),
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          icon!,
                          const SizedBox(width: 8),
                        ],
                        if (label != null)
                          Text(
                            label!,
                            style: AppStyles.labelMd.copyWith(
                              color: foregroundColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (showArrow) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            color: foregroundColor,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
