import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Light palette (Gold/Cream Editorial) ──
const _lightBackground = Color(0xFFF2EFE8);
const _lightCream = Color(0xFFFAF8F3);
const _lightSurface = Color(0xFFFFFFFF);
const _lightGold = Color(0xFFC9A84C);
const _lightGoldLight = Color(0xFFE8C96A);
const _lightTextPrimary = Color(0xFF1A1714);
const _lightTextSecondary = Color(0xFF8A8075);
const _lightError = Color(0xFFBA1A1A);

// ── Dark palette (Navy Editorial) ──
const _darkBackground = Color(0xFF0D1B2A);
const _darkSurface = Color(0xFF1F3347);
const _darkNavyMid = Color(0xFF1A2E42);
const _darkGold = Color(0xFFC9A84C);
const _darkGoldLight = Color(0xFFE8C96A);
const _darkTextPrimary = Color(0xFFFAF8F3);
const _darkTextSecondary = Color(0x66FAF8F3); // 40% opacity
const _darkError = Color(0xFFFFB4AB);

// ── Shared radius ──
const kCardRadius = 28.0;
const kPillRadius = 24.0;

// ── Text theme builder (Playfair Display headings, DM Sans body) ──
TextTheme _buildTextTheme(Color primary, Color secondary) {
  final display = GoogleFonts.playfairDisplayTextTheme();
  final body = GoogleFonts.dmSansTextTheme();
  return TextTheme(
    displayLarge: display.displayLarge?.copyWith(
        fontSize: 32, fontWeight: FontWeight.w700, color: primary),
    titleLarge: display.titleLarge?.copyWith(
        fontSize: 28, fontWeight: FontWeight.w700, color: primary),
    titleMedium: display.titleMedium?.copyWith(
        fontSize: 22, fontWeight: FontWeight.w600, color: primary),
    bodyLarge: body.bodyLarge?.copyWith(
        fontSize: 16, fontWeight: FontWeight.w400, color: primary),
    bodyMedium: body.bodyMedium?.copyWith(
        fontSize: 14, fontWeight: FontWeight.w400, color: secondary),
    bodySmall: body.bodySmall?.copyWith(
        fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
    labelLarge: body.labelLarge?.copyWith(
        fontSize: 16, fontWeight: FontWeight.w600, color: primary),
    labelMedium: body.labelMedium?.copyWith(
        fontSize: 14, fontWeight: FontWeight.w400, color: secondary),
    labelSmall: body.labelSmall?.copyWith(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: secondary,
        letterSpacing: 1.2),
  );
}

// ── Light Theme ──
final lightTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: _lightBackground,
  colorScheme: const ColorScheme.light(
    primary: _lightTextPrimary, // Dark primary buttons in light mode
    secondary: _lightGold,
    tertiary: _lightGoldLight,
    surface: _lightSurface,
    error: _lightError,
    onPrimary: Colors.white,
    onSecondary: _lightTextPrimary,
    onSurface: _lightTextPrimary,
    onSurfaceVariant: _lightTextSecondary,
    outline: Color(0xFFE8E3D9),
    outlineVariant: Color(0xFFE8E3D9),
    primaryContainer: _lightCream,
    onPrimaryContainer: _lightTextPrimary,
    secondaryContainer: Color(0x26C9A84C), // gold 15%
    onSecondaryContainer: _lightGold,
    surfaceContainerHighest: Color(0xFFF0EDE5),
  ),
  textTheme: _buildTextTheme(_lightTextPrimary, _lightTextSecondary),
  appBarTheme: AppBarTheme(
    backgroundColor: _lightBackground,
    foregroundColor: _lightTextPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.playfairDisplay(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: _lightTextPrimary,
    ),
  ),
  cardTheme: CardThemeData(
    color: _lightSurface,
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: 0.04),
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kCardRadius),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: _lightTextPrimary,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 52),
      textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kPillRadius)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _lightTextPrimary,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 52),
      textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kPillRadius)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: _lightTextPrimary,
      minimumSize: const Size(double.infinity, 52),
      textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kPillRadius)),
      side: const BorderSide(color: Color(0xFFE8E3D9)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: _lightGold,
      textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    filled: true,
    fillColor: _lightSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE8E3D9)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE8E3D9)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _lightGold, width: 2),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: _lightSurface,
    selectedColor: _lightTextPrimary,
    labelStyle: GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w500, color: _lightTextPrimary),
    secondaryLabelStyle: GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFE8E3D9)),
    ),
    showCheckmark: false,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: _lightGold,
    linearTrackColor: Color(0xFFF0EDE5),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: _lightTextPrimary,
    foregroundColor: Colors.white,
    shape: const CircleBorder(),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFFE8E3D9)),
  materialTapTargetSize: MaterialTapTargetSize.padded,
);

// ── Dark Theme ──
final darkTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: _darkBackground,
  colorScheme: const ColorScheme.dark(
    primary: _darkGold,
    secondary: _darkGold,
    tertiary: _darkGoldLight,
    surface: _darkSurface,
    error: _darkError,
    onPrimary: _darkBackground,
    onSecondary: _darkBackground,
    onSurface: _darkTextPrimary,
    onSurfaceVariant: _darkTextSecondary,
    outline: Color(0xFF2A3F5F),
    outlineVariant: Color(0xFF2A3F5F),
    primaryContainer: _darkNavyMid,
    onPrimaryContainer: _darkGold,
    secondaryContainer: Color(0x26C9A84C), // gold 15%
    onSecondaryContainer: _darkGold,
    surfaceContainerHighest: Color(0xFF243B56),
  ),
  textTheme: _buildTextTheme(_darkTextPrimary, _darkTextSecondary),
  appBarTheme: AppBarTheme(
    backgroundColor: _darkBackground,
    foregroundColor: _darkTextPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.playfairDisplay(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: _darkTextPrimary,
    ),
  ),
  cardTheme: CardThemeData(
    color: _darkSurface,
    elevation: 4,
    shadowColor: Colors.black.withValues(alpha: 0.3),
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kCardRadius),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: _darkGold,
      foregroundColor: _darkBackground,
      minimumSize: const Size(double.infinity, 52),
      textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kPillRadius)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _darkGold,
      foregroundColor: _darkBackground,
      minimumSize: const Size(double.infinity, 52),
      textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kPillRadius)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: _darkTextPrimary,
      minimumSize: const Size(double.infinity, 52),
      textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kPillRadius)),
      side: const BorderSide(color: Color(0xFF2A3F5F)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: _darkGold,
      textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    filled: true,
    fillColor: _darkSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF2A3F5F)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF2A3F5F)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _darkGold, width: 2),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: _darkSurface,
    selectedColor: _darkGold,
    labelStyle: GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w500, color: _darkTextPrimary),
    secondaryLabelStyle: GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w500, color: _darkBackground),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFF2A3F5F)),
    ),
    showCheckmark: false,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: _darkGold,
    linearTrackColor: Color(0xFF243B56),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: _darkGold,
    foregroundColor: _darkBackground,
    shape: CircleBorder(),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFF2A3F5F)),
  materialTapTargetSize: MaterialTapTargetSize.padded,
);

/// Extension for easy access to custom colors not in ColorScheme
extension WhatnowColors on ColorScheme {
  Color get cardBorder => outline;
  Color get gold => brightness == Brightness.dark
      ? const Color(0xFFC9A84C)
      : const Color(0xFFC9A84C);
  Color get goldLight => brightness == Brightness.dark
      ? const Color(0xFFE8C96A)
      : const Color(0xFFE8C96A);
  Color get goldDim => brightness == Brightness.dark
      ? const Color(0x26C9A84C)
      : const Color(0x26C9A84C);
  Color get cream => brightness == Brightness.dark
      ? const Color(0xFF0D1B2A)
      : const Color(0xFFFAF8F3);
}
