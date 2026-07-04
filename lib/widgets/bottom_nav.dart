import 'package:flutter/material.dart';
import '../constants/app_styles.dart';
import '../constants/colors.dart';

enum BottomNavTab { home, profile }

class BottomNav extends StatelessWidget {
  final BottomNavTab activeTab;
  final Function(BottomNavTab) onTabChange;

  const BottomNav({
    Key? key,
    required this.activeTab,
    required this.onTabChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.neutral200)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavItem(
              tab: BottomNavTab.home,
              activeTab: activeTab,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
              onTap: onTabChange,
            ),
            _NavItem(
              tab: BottomNavTab.profile,
              activeTab: activeTab,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              onTap: onTabChange,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final BottomNavTab tab;
  final BottomNavTab activeTab;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Function(BottomNavTab) onTap;

  const _NavItem({
    required this.tab,
    required this.activeTab,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = tab == activeTab;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => onTap(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.coral : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? Colors.white : AppColors.neutral500,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppStyles.labelSm.copyWith(
                  color: isActive ? Colors.white : AppColors.neutral500,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
