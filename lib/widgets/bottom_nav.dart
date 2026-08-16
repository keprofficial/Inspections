import 'package:flutter/material.dart';
import '../constants/app_styles.dart';
import '../constants/colors.dart';

/// The four nouns the inspector actually thinks in.
///
/// Replaces the old two-item nav, which buried report history inside Profile
/// and left the active inspection with no stable address.
enum AppTab { home, inspect, reports, profile }

extension AppTabDisplay on AppTab {
  String get label {
    switch (this) {
      case AppTab.home:
        return 'Home';
      case AppTab.inspect:
        return 'Inspect';
      case AppTab.reports:
        return 'Reports';
      case AppTab.profile:
        return 'Me';
    }
  }

  IconData get icon {
    switch (this) {
      case AppTab.home:
        return Icons.home_outlined;
      case AppTab.inspect:
        return Icons.checklist_outlined;
      case AppTab.reports:
        return Icons.description_outlined;
      case AppTab.profile:
        return Icons.person_outline;
    }
  }

  IconData get activeIcon {
    switch (this) {
      case AppTab.home:
        return Icons.home;
      case AppTab.inspect:
        return Icons.checklist;
      case AppTab.reports:
        return Icons.description;
      case AppTab.profile:
        return Icons.person;
    }
  }
}

class BottomNav extends StatelessWidget {
  final AppTab activeTab;
  final ValueChanged<AppTab> onTabChange;

  /// Shown as a dot on the Inspect tab when an inspection is in progress.
  final bool hasActiveInspection;

  const BottomNav({
    Key? key,
    required this.activeTab,
    required this.onTabChange,
    this.hasActiveInspection = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.neutral200)),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            for (final tab in AppTab.values)
              _NavItem(
                tab: tab,
                activeTab: activeTab,
                onTap: onTabChange,
                showDot: tab == AppTab.inspect && hasActiveInspection,
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppTab tab;
  final AppTab activeTab;
  final ValueChanged<AppTab> onTap;
  final bool showDot;

  const _NavItem({
    required this.tab,
    required this.activeTab,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = tab == activeTab;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: tab.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: () => onTap(tab),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTapTarget,
            ),
            height: AppSizes.navBarHeight,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isActive ? AppColors.coral : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isActive ? tab.activeIcon : tab.icon,
                      color: isActive ? Colors.white : AppColors.neutral500,
                      size: 21,
                    ),
                    if (showDot)
                      Positioned(
                        right: -3,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.white : AppColors.coral,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.labelSm.copyWith(
                      fontSize: 11,
                      color: isActive ? Colors.white : AppColors.neutral500,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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
