// services/supabase_config.dart

class SupabaseConfig {
  /// Supabase Dashboard -> Project Settings -> API kısmından alacağınız Project URL
  static const String supabaseUrl = 'https://ukmhivcvnnyasrcjcezw.supabase.co';

  /// Supabase Dashboard -> Project Settings -> API kısmından alacağınız anon / public API anahtarı
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVrbWhpdmN2bm55YXNyY2pjZXp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc2ODMyNzUsImV4cCI6MjEwMzI1OTI3NX0.2RyyQ1KyzTx9jjwDPTAg4XIlZ2-sJIuWxbegzCHuleE';

  /// Gerçek anahtarların girilip girilmediğini kontrol eder
  static bool get isConfigured {
    return supabaseUrl.startsWith('https://') &&
        !supabaseUrl.contains('YOUR_SUPABASE_PROJECT_ID') &&
        supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
        supabaseAnonKey.isNotEmpty;
  }
}
