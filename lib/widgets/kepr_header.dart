import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'kepr_logo.dart';

class KeprHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final bool showMenu;
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationTap;

  const KeprHeader({
    Key? key,
    this.title,
    this.subtitle,
    this.showMenu = true,
    this.onMenuTap,
    this.onNotificationTap,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.coral,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const KeprLogo(size: 38),
          if (title != null) ...[
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: showMenu
          ? [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: onNotificationTap,
              ),
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: onMenuTap,
              ),
            ]
          : null,
    );
  }
}
