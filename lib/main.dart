import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/env.dart';
import 'services/consent_service.dart';
import 'services/revenue_cat_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await SentryFlutter.init(
    (options) {
      options.dsn = Env.sentryDsn;
      options.tracesSampleRate = 0.0; // Crash reporting only, no perf tracing
    },
    appRunner: () async {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
      );

      // Initialize RevenueCat (identifies user if already logged in)
      await RevenueCatService.instance.init();

      // GDPR: collect consent before initializing ads
      await ConsentService.instance.initialize();

      // Only initialize ads SDK after consent check
      if (ConsentService.instance.canRequestAds) {
        MobileAds.instance.initialize();
      }

      runApp(const ProviderScope(child: WhatnowApp()));
    },
  );
}
