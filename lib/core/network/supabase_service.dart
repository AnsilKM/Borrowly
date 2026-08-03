import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String defaultUrl = 'https://wjgvdryrtgajenlcbjfy.supabase.co';
  static const String defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqZ3ZkcnlydGdhamVubGNiamZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUzOTk2MDYsImV4cCI6MjEwMDk3NTYwNn0.OQQfNd6Xy-BLg_vMRD6Ip0rUTA3AF54OOwR5lncept4';

  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Supabase.initialize(
        url: defaultUrl,
        // ignore: deprecated_member_use
        anonKey: defaultAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        debug: kDebugMode,
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Supabase initialization notice (Running in offline/mock mode): $e');
      _isInitialized = false;
    }
  }

  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool get isConfigured => client != null;
}
