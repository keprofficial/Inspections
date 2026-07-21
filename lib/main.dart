import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/inspections_dashboard_screen.dart';
import 'screens/signin_screen.dart';
import 'services/inspection_draft_storage.dart';
import 'services/inspection_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }
  await InspectionDraftStorage.restoreSession();

  runApp(const KeprApp());
}

class KeprApp extends StatelessWidget {
  const KeprApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kepr - Safety Inspection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Manrope',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF85F5A),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: InspectionSession.hasFreshInspectorSession &&
              InspectionSession.isActive
          ? const InspectionsDashboardScreen()
          : const SignInScreen(),
    );
  }
}
