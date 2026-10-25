import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized && isConfigured;

  static bool get isConfigured {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    return url.isNotEmpty &&
        !url.contains('your-project') &&
        !url.contains('placeholder') &&
        key.isNotEmpty &&
        !key.contains('your-anon-key');
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('.env file not found or empty, using environment fallback: $e');
    }

    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://placeholder.supabase.co';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'placeholder-anon-key';

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Supabase initialization warning (demo mode active): $e');
      _isInitialized = false;
    }
  }
}
