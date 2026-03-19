import 'package:flutter/material.dart';

/// Brand colors for onboarding screens — gold/cream editorial palette.
abstract final class OnboardingTheme {
  static const gold = Color(0xFFC9A84C);
  static const goldLight = Color(0xFFE8C96A);
  static const cream = Color(0xFFFAF8F3);

  // Theme-aware helpers
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color cardColor(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}
