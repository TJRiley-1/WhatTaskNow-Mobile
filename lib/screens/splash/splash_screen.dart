import 'package:flutter/material.dart';
import '../../config/onboarding_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: OnboardingTheme.gold,
        ),
      ),
    );
  }
}
