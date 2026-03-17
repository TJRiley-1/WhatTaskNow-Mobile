import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Light palette ──
const _lightBackground = Color(0xFFF5F5F0);
const _lightSurface = Color(0xFFFFFFFF);
const _lightPrimary = Color(0xFFFF8C00);
const _lightSecondary = Color(0xFF20B2AA);
const _lightTextPrimary = Color(0xFF1A3B66);
const _lightTextSecondary = Color(0xFF607D8B);
const _lightCardBorder = Color(0xFFE8E8E3);
const _lightError = Color(0xFFBA1A1A);

// ── Dark palette ──
const _darkBackground = Color(0xFF0D1B2A);
const _darkSurface = Color(0xFF1B2D44);
const _darkPrimary = Color(0xFFFFB347);
const _darkSecondary = Color(0xFF5BCFCF);
const _darkTextPrimary = Color(0xFFE8E4DC);
const _darkTextSecondary = Color(0xFF8899AA);
const _darkCardBorder = Color(0xFF2A3F5F);
const _darkGold = Color(0xFFD4A853);
const _darkError = Color(0xFFFFB4AB);

// ── Shared radius ──
const kCardRadius = 20.0;
const kPillRadius = 24.0;

// ── Text theme builder ──
TextTheme _buildTextTheme(Color primary, Color secondary) {
  return GoogleFonts.interTextTheme(
    TextTheme(
      displayLarge: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w700, color: primary),
      titleLarge: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w700, color: primary),
      titleMedium: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400, color: primary),
      bodyMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400, color: secondary),
      bodySmall: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500, color: secondary),
      labelLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      labelMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w400, color: secondary),
    ),
  );
}

// ── Light Theme ──
final lightTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: _lightBackground,
  colorScheme: const ColorScheme.light(
    primary: _lightPrimary,
    secondary: _lightSecondary,
    surface: _lightSurface,
    error: _lightError,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: _lightTextPrimary,
    onSurfaceVariant: _lightTextSecondary,
    outline: _lightCardBorder,
    outlineVariant: _lightCardBorder,
    primaryContainer: Color(0xFFFFE0B2),
    onPrimaryContainer: Color(0xFF5D3200),
    secondaryContainer: Color(0xFFB2DFDB),
    onSecondaryContainer: Color(0xFF00332E),
    surfaceContainerHighest: Color(0xFFEEEDE8),
  ),
  textTheme: _buildTextTheme(_lightTextPrimary, _lightTextSecondary),
  appBarTheme: AppBarTheme(
    backgroundColor: _lightBackground,
    foregroundColor: _lightTextPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: _lightTextPrimary,
    ),
  ),
  cardTheme: CardThemeData(
    color: _lightSurface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kCardRadius),
      side: const BorderSide(color: _lightCardBorder),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: _lightPrimary,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 52),
      textStyle: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kPillRadius)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _lightPrimary,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 52),
      textStyle: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kPillRadius)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: _lightTextPrimary,
      minimumSize: const Size(double.infinity, 52),
      textStyle: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kPillRadius)),
      side: const BorderSide(color: _lightCardBorder),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: _lightPrimary,
      textStyle: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    filled: true,
    fillColor: _lightSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _lightCardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _lightCardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _lightPrimary, width: 2),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: _lightSurface,
    selectedColor: _lightPrimary.withValues(alpha: 0.15),
    labelStyle: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w500, color: _lightTextPrimary),
    secondaryLabelStyle: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w500, color: _lightTextPrimary),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: _lightCardBorder),
    ),
    showCheckmark: false,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: _lightPrimary,
    linearTrackColor: Color(0xFFEEEDE8),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: _lightPrimary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kPillRadius)),
  ),
  dividerTheme: const DividerThemeData(color: _lightCardBorder),
  materialTapTargetSize: MaterialTapTargetSize.padded,
);

// ── Dark Theme ──
final darkTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: _darkBackground,
  colorScheme: const ColorScheme.dark(
    primary: _darkPrimary,
    secondary: _darkSecondary,
    surface: _darkSurface,
    error: _darkError,
    onPrimary: Color(0xFF1A1A1A),
    onSecondary: Color(0xFF1A1A1A),
    onSurface: _darkTextPrimary,
    onSurfaceVariant: _darkTextSecondary,
    outline: _darkCardBorder,
    outlineVariant: _darkCardBorder,
    primaryContainer: Color(0xFF3D2800),
    onPrimaryContainer: _darkGold,
    secondaryContainer: Color(0xFF0A3D3D),
    onSecondaryContainer: _darkSecondary,
    surfaceContainerHighest: Color(0xFF243B56),
    tertiary: _darkGold,
  ),
  textTheme: _buildTextTheme(_darkTextPrimary, _darkTextSecondary),
  appBarTheme: AppBarTheme(
    backgroundColor: _darkBackground,
    foregroundColor: _darkTextPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: _darkTextPrimary,
    ),
  ),
  cardTheme: CardThemeData(
    color: _darkSurface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kCardRadius),
      side: const BorderSide(color: _darkCardBorder),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: _darkPrimary,
      foregroundColor: const Color(0xFF1A1A1A),
      minimumSize: const Size(double.infinity, 52),
      textStyle: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kPillRadius)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _darkPrimary,
      foregroundColor: const Color(0xFF1A1A1A),
      minimumSize: const Size(double.infinity, 52),
      textStyle: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kPillRadius)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: _darkTextPrimary,
      minimumSize: const Size(double.infinity, 52),
      textStyle: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kPillRadius)),
      side: const BorderSide(color: _darkCardBorder),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: _darkPrimary,
      textStyle: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    filled: true,
    fillColor: _darkSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _darkCardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _darkCardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _darkPrimary, width: 2),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: _darkSurface,
    selectedColor: _darkPrimary.withValues(alpha: 0.2),
    labelStyle: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w500, color: _darkTextPrimary),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: _darkCardBorder),
    ),
    showCheckmark: false,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: _darkGold,
    linearTrackColor: Color(0xFF243B56),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: _darkGold,
    foregroundColor: const Color(0xFF1A1A1A),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kPillRadius)),
  ),
  dividerTheme: const DividerThemeData(color: _darkCardBorder),
  materialTapTargetSize: MaterialTapTargetSize.padded,
);

/// Extension for easy access to custom colors not in ColorScheme
extension WhatnowColors on ColorScheme {
  Color get cardBorder => outline;
  Color get gold => brightness == Brightness.dark
      ? const Color(0xFFD4A853)
      : const Color(0xFFFF8C00);
}
