import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';

class WhatnowApp extends ConsumerStatefulWidget {
  const WhatnowApp({super.key});

  @override
  ConsumerState<WhatnowApp> createState() => _WhatnowAppState();
}

class _WhatnowAppState extends ConsumerState<WhatnowApp> {
  late final AuthNotifier _authNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authNotifier = AuthNotifier();
    _router = createRouter(_authNotifier);
  }

  @override
  void dispose() {
    _authNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Whatnow',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: _router,
    );
  }
}
