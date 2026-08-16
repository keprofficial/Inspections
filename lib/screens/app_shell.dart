import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/inspection_session.dart';
import '../services/sync_status.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/sync_indicator.dart';
import 'home_screen.dart';
import 'inspect_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';

/// The authenticated application shell.
///
/// Owns the bottom navigation, the offline banner, and the lifetime of each
/// tab body. Tab bodies are kept alive in an [IndexedStack] so switching to
/// Reports and back does not discard a loaded checklist or scroll position.
class AppShell extends StatefulWidget {
  final AppTab initialTab;

  const AppShell({Key? key, this.initialTab = AppTab.home}) : super(key: key);

  @override
  State<AppShell> createState() => AppShellState();

  /// Lets a descendant switch tabs, e.g. Home's "See all reports".
  static AppShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<AppShellState>();
  }
}

class AppShellState extends State<AppShell> {
  late AppTab _activeTab;

  /// Bumped to force the Home and Reports tabs to refetch after a submit.
  int _dataRevision = 0;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    SyncStatus.instance.start();
  }

  void goToTab(AppTab tab) {
    if (!mounted) return;
    setState(() => _activeTab = tab);
  }

  /// Call after a submit or a new inspection starts so dependent tabs reload.
  void refreshData() {
    if (!mounted) return;
    setState(() => _dataRevision++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: IndexedStack(
              index: _activeTab.index,
              children: [
                HomeScreen(key: ValueKey('home-$_dataRevision')),
                const InspectScreen(),
                ReportsScreen(key: ValueKey('reports-$_dataRevision')),
                ProfileScreen(key: ValueKey('profile-$_dataRevision')),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        activeTab: _activeTab,
        hasActiveInspection: InspectionSession.isActive,
        onTabChange: goToTab,
      ),
    );
  }
}
