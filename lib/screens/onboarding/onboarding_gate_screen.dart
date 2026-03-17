import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/profile_provider.dart';
import '../home/what_now_screen.dart';

/// Gate widget that sits at the `/` route.
/// Redirects to onboarding if the user hasn't completed it yet.
class OnboardingGateScreen extends ConsumerWidget {
  const OnboardingGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const WhatNowScreen(), // fallback to main screen
      data: (profile) {
        if (profile != null && !profile.onboardingCompleted) {
          // Schedule navigation after build
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
