import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/profile_provider.dart';
import '../home/what_now_screen.dart';

/// Whether onboarding is done — checks Supabase profile first,
/// falls back to SharedPreferences (covers pre-migration installs).
final _onboardingDoneProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile != null && profile.onboardingCompleted) return true;

  // Fallback: check local flag (set when Supabase update fails)
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') ?? false;
});

/// Gate widget that sits at the `/` route.
/// Redirects to onboarding if the user hasn't completed it yet.
class OnboardingGateScreen extends ConsumerWidget {
  const OnboardingGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doneAsync = ref.watch(_onboardingDoneProvider);

    return doneAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const WhatNowScreen(),
      data: (done) {
        if (!done) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/onboarding');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const WhatNowScreen();
      },
    );
  }
}
