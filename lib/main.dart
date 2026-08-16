import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'constants/colors.dart';
import 'screens/signin_screen.dart';
import 'services/inspection_draft_storage.dart';
import 'services/sync_status.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }
  await InspectionDraftStorage.restoreSession();
  await SyncStatus.instance.start();

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
          seedColor: AppColors.coral,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.neutral50,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      // The gate picks login or the shell; the shell opens on Inspect when a
      // restored inspection is active so a refresh lands where the user left.
      home: const SignInScreen(),
    );
  }
}
