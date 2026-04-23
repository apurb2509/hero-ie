import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── DARK PALETTE — Amber / Gold ─────────────────────────────────────
  static const Color primaryNeon    = Color(0xFFFFB347); // Amber-Gold (global dark primary)
  static const Color primaryNeonSoft= Color(0xFFFFCC80); // Lighter amber (gradient end)
  static const Color backgroundMatte = Color(0xFF0D0A00); // Near-black amber-tinted
  static const Color surfaceColor   = Color(0xFF1A1400); // Dark surface
  static const Color surfaceElevated = Color(0xFF201A00); // Cards

  // ── LIGHT PALETTE — Dark Amber / Goldenrod ───────────────────────────
  static const Color primaryLight   = Color(0xFFC97B1A); // Dark amber (readable on white)
  static const Color primaryLightSoft = Color(0xFFE59A2A); // Lighter amber for gradients
  static const Color backgroundLight = Color(0xFFFFF9F0); // Warm off-white
  static const Color surfaceLight   = Color(0xFFFFFFFF);

  // ── SEMANTIC COLORS ──────────────────────────────────────────────────
  static const Color errorNeon    = Color(0xFFFF3B55); // SOS Red
  static const Color warningNeon  = Color(0xFFFFCC00); // Neon Yellow

  // ── THEME NOTIFIER ───────────────────────────────────────────────────
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.dark);

  // ── DARK THEME ───────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundMatte,
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        secondary: primaryNeonSoft,
        surface: surfaceElevated,
        error: errorNeon,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge:  GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.white),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
        headlineSmall: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
        bodyLarge:     GoogleFonts.outfit(color: Color(0xAAFFFFFF)),
        bodyMedium:    GoogleFonts.outfit(color: Color(0x88FFFFFF)),
        labelLarge:    GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNeon,
          foregroundColor: backgroundMatte,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryNeon,
          side: const BorderSide(color: primaryNeon, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      cardTheme: const CardThemeData(
        color: surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0x1AFFB347)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundMatte,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryNeon),
        foregroundColor: Colors.white,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: backgroundMatte,
        elevation: 0,
      ),
      dividerColor: Color(0x1AFFB347),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primaryNeon : Colors.grey,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? const Color(0x44FFB347)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: GoogleFonts.outfit(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── LIGHT THEME ──────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const Color textDark = Color(0xFF1A0D00);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: primaryLightSoft,
        surface: surfaceLight,
        error: errorNeon,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge:  GoogleFonts.outfit(fontWeight: FontWeight.w800, color: textDark),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textDark),
        headlineSmall: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textDark),
        bodyLarge:     GoogleFonts.outfit(color: Color(0xFF4A2E00)),
        bodyMedium:    GoogleFonts.outfit(color: Color(0xFF6A4A10)),
        labelLarge:    GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: primaryLight.withValues(alpha: 0.2)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryLight),
        foregroundColor: textDark,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: backgroundLight,
        elevation: 0,
      ),
      dividerColor: Color(0x30C97B1A),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primaryLight : Colors.grey,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? const Color(0x44C97B1A)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2A1800),
        contentTextStyle: GoogleFonts.outfit(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────

  /// Primary accent for the current theme.
  static Color accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primaryNeon : primaryLight;

  /// Soft/secondary accent (gradient end).
  static Color accentSoft(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primaryNeonSoft : primaryLightSoft;

  /// Auth accent is now the same as the primary (yellow globally).
  static Color authAccent(BuildContext context) => accent(context);

  static InputDecoration inputDecoration(String label,
      {Color? focusColor, bool isLightMode = false}) {
    final defaultFocus =
        focusColor ?? (isLightMode ? primaryLight : primaryNeon);
    final borderColor = isLightMode
        ? const Color(0xFFDEB887)   // burlywood — warm amber border
        : const Color(0x22FFB347);
    final labelColor =
        isLightMode ? const Color(0xFF8B6020) : const Color(0x88FFFFFF);
    final fillCol = isLightMode
        ? Colors.white
        : const Color(0x0AFFB347);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelColor),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: defaultFocus, width: 1.5),
      ),
      filled: true,
      fillColor: fillCol,
    );
  }
}
