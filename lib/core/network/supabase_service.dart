import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String defaultUrl = 'https://borrowly-supabase-project.supabase.co';
  static const String defaultAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.borrowly_anon_token';

  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Supabase.initialize(
        url: defaultUrl,
        anonKey: defaultAnonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Supabase initialization notice (Running in offline/mock mode): $e');
      _isInitialized = false;
    }
  }

  static SupabaseClient? get client {
    if (_isInitialized) {
      return Supabase.instance.client;
    }
    return null;
  }

  static bool get isConfigured => _isInitialized && client != null;
}
