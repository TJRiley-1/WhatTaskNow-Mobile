import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;
  static String get sentryDsn => dotenv.env['SENTRY_DSN'] ?? '';
  static String get revenueCatAppleKey =>
      dotenv.env['REVENUECAT_APPLE_KEY'] ?? '';
  static String get revenueCatGoogleKey =>
      dotenv.env['REVENUECAT_GOOGLE_KEY'] ?? '';
}
