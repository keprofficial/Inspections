import 'package:flutter/material.dart';

import '../services/inspection_draft_storage.dart';
import '../services/inspection_session.dart';
import '../widgets/bottom_nav.dart';
import 'app_shell.dart';
import 'login_screen.dart';

/// The authentication gate.
///
/// This file used to hold login, the inspector home, the mode/plan pickers,
/// and the property pickers all at once. Those now live in [LoginScreen],
/// `HomeScreen`, and `StartInspectionFlow`. The gate is kept under the
/// original name because it is the app's entry point and the target of every
/// "back to the start" navigation in the codebase.
class SignInScreen extends StatefulWidget {
  /// Which tab to open when the inspector already has a valid session.
  /// Defaults to Inspect when an inspection is in progress, so a browser
  /// refresh returns to the work rather than the home screen.
  final AppTab? initialTab;

  const SignInScreen({Key? key, this.initialTab}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _authenticated = InspectionSession.hasFreshInspectorSession;
    if (!_authenticated && (InspectionSession.authToken ?? '').isNotEmpty) {
      // A stale token is worse than none — drop it so the user is not shown a
      // signed-in shell that fails on the first RPC.
      InspectionSession.clearInspectorAuth();
      InspectionDraftStorage.saveSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) {
      return AppShell(
        initialTab: widget.initialTab ??
            (InspectionSession.isActive ? AppTab.inspect : AppTab.home),
      );
    }
    return LoginScreen(
      onAuthenticated: () {
        if (mounted) setState(() => _authenticated = true);
      },
    );
  }
}
