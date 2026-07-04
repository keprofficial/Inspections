class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://egalrsutygdvdmjkvduh.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_Odebo_AnNPzq9p2Dpy1lGg_3wKogYCh',
  );

  static bool get isConfigured =>
      url.isNotEmpty &&
      publishableKey.isNotEmpty &&
      publishableKey != 'YOUR_SUPABASE_ANON_KEY';
}
