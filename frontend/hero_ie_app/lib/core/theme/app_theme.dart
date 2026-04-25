import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeType { midnightCyan, cyberPurple, emeraldMatrix, crimsonAlert, asteroidBlack, lightOasis }

extension AppThemeTypeExt on AppThemeType {
  String get title {
    switch (this) {
      case AppThemeType.midnightCyan: return 'Midnight Cyan';
      case AppThemeType.cyberPurple: return 'Cyber Purple';
      case AppThemeType.emeraldMatrix: return 'Emerald Matrix';
      case AppThemeType.crimsonAlert: return 'Crimson Alert';
      case AppThemeType.asteroidBlack: return 'Asteroid Black';
      case AppThemeType.lightOasis: return 'Light Oasis';
    }
  }
}

class AppTheme {
  // ── THEME STATE ──────────────────────────────────────────────────────
  static final ValueNotifier<AppThemeType> themeNotifier =
      ValueNotifier(AppThemeType.midnightCyan);

  static void cycleTheme() {
    final v = AppThemeType.values;
    final nextIndex = (themeNotifier.value.index + 1) % v.length;
    themeNotifier.value = v[nextIndex];
  }

  // ── PALETTE GENERATORS ───────────────────────────────────────────────
  static Color _getAccent(AppThemeType type) {
    switch (type) {
      case AppThemeType.midnightCyan:  return const Color(0xFF00E5FF); // Neon Cyan
      case AppThemeType.cyberPurple:   return const Color(0xFFB026FF); // Electric Purple
      case AppThemeType.emeraldMatrix: return const Color(0xFF00FF66); // Hacker Green
      case AppThemeType.crimsonAlert:  return const Color(0xFFFF3333); // Alert Red
      case AppThemeType.asteroidBlack: return const Color(0xFFFFFFFF); // Pure White
      case AppThemeType.lightOasis:    return const Color(0xFF0066FF); // Trust Blue
    }
  }

  static Color _getBg(AppThemeType type) {
    switch (type) {
      case AppThemeType.midnightCyan:  return const Color(0xFF050A14); // Deep Navy Black
      case AppThemeType.cyberPurple:   return const Color(0xFF0B0410); // Deep Dark Violet
      case AppThemeType.emeraldMatrix: return const Color(0xFF040A05); // Deep Dark Green
      case AppThemeType.crimsonAlert:  return const Color(0xFF100505); // Deep Dark Red
      case AppThemeType.asteroidBlack: return const Color(0xFF000000); // Pitch Deep Space Black
      case AppThemeType.lightOasis:    return const Color(0xFFFAFAFC); // Clean Off-White
    }
  }

  static Color _getSurface(AppThemeType type) {
    switch (type) {
      case AppThemeType.midnightCyan:  return const Color(0xFF0C1424);
      case AppThemeType.cyberPurple:   return const Color(0xFF140822);
      case AppThemeType.emeraldMatrix: return const Color(0xFF08140B);
      case AppThemeType.crimsonAlert:  return const Color(0xFF1A0808);
      case AppThemeType.asteroidBlack: return const Color(0xFF111111); // Deep Card Grey Surface
      case AppThemeType.lightOasis:    return const Color(0xFFFFFFFF);
    }
  }

  static Color _getBorder(AppThemeType type) {
    if (type == AppThemeType.lightOasis) return const Color(0xFFE4E4E7);
    return const Color(0xFF27272A).withValues(alpha: 0.5);
  }

  // ── FULL THEME GENERATOR ─────────────────────────────────────────────
  static ThemeData generateTheme(AppThemeType type) {
    final isDark = type != AppThemeType.lightOasis;
    
    final accent = _getAccent(type);
    final bg = _getBg(type);
    final surface = _getSurface(type);
    final border = _getBorder(type);

    final textOnBg = (type == AppThemeType.asteroidBlack || isDark) ? const Color(0xFFE4E4E7) : const Color(0xFF09090B);
    final textOnSurface = (type == AppThemeType.asteroidBlack) ? const Color(0xFFFFFFFF) : (isDark ? const Color(0xFFE4E4E7) : const Color(0xFF3F3F46));
    
    final textMutedOnBg = (type == AppThemeType.asteroidBlack || isDark) ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    final textHeadingOnBg = (type == AppThemeType.asteroidBlack || isDark) ? Colors.white : const Color(0xFF09090B);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: accent,
        onPrimary: (type == AppThemeType.asteroidBlack || !isDark) ? const Color(0xFF0A0A0A) : Colors.white,
        secondary: accent.withValues(alpha: 0.7),
        onSecondary: Colors.white,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
        surface: surface,
        onSurface: textOnSurface,
        surfaceContainer: surface, // Modern alias
        onSurfaceVariant: textOnSurface.withValues(alpha: 0.7),
        background: bg, // Legacy but used
        onBackground: textOnBg,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData(brightness: isDark ? Brightness.dark : Brightness.light).textTheme,
      ).copyWith(
        displayLarge:  GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: textHeadingOnBg, letterSpacing: -1.0),
        displayMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: textHeadingOnBg, letterSpacing: -0.5),
        headlineSmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: textHeadingOnBg),
        bodyLarge:     GoogleFonts.plusJakartaSans(color: textOnBg, fontWeight: FontWeight.w500),
        bodyMedium:    GoogleFonts.plusJakartaSans(color: textMutedOnBg),
        labelLarge:    GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: (type == AppThemeType.asteroidBlack) ? Colors.white : Colors.white, letterSpacing: 0.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: (type == AppThemeType.asteroidBlack || !isDark) ? const Color(0xFF0A0A0A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.5),
          elevation: isDark ? 8 : 0,
          shadowColor: accent.withValues(alpha: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: (type == AppThemeType.asteroidBlack) ? const Color(0xFFE4E4E7) : (isDark ? Colors.white : const Color(0xFF09090B)),
          side: BorderSide(color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: border),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: (type == AppThemeType.asteroidBlack) ? const Color(0xFFFFFFFF) : (isDark ? Colors.white : const Color(0xFF09090B))),
        foregroundColor: (type == AppThemeType.asteroidBlack) ? const Color(0xFFFFFFFF) : textHeadingOnBg,
        titleTextStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 18, color: (type == AppThemeType.asteroidBlack) ? const Color(0xFFFFFFFF) : textHeadingOnBg),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        elevation: 0,
      ),
      dividerColor: border,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : (isDark ? const Color(0xFFA1A1AA) : Colors.grey),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? accent
              : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7)),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFF09090B),
        contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── HELPERS FOR LEGACY COMPONENTS ────────────────────────────────────
  static Color accent(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color accentSoft(BuildContext context) => Theme.of(context).colorScheme.secondary;
  
  static Color get backgroundMatte => _getBg(themeNotifier.value);
  static Color get backgroundLight => _getBg(AppThemeType.lightOasis);

  // Backward compatibility getters
  static Color get primaryNeon => _getAccent(themeNotifier.value);
  static Color get primaryNeonSoft => primaryNeon.withValues(alpha: 0.7);
  static Color get warningNeon => const Color(0xFFF59E0B);
  static Color get errorNeon => const Color(0xFFEF4444);
  static Color get surfaceColor => _getSurface(themeNotifier.value);
  static ThemeData get lightTheme => generateTheme(AppThemeType.lightOasis);

  static Color authAccent(BuildContext context) => accent(context);

  static InputDecoration inputDecoration(String label, {Color? focusColor, bool isLightMode = false}) {
    final type = themeNotifier.value;
    final isDark = type != AppThemeType.lightOasis;

    final defaultFocus = focusColor ?? _getAccent(type);
    final borderColor = isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7);
    final textColor = (type == AppThemeType.asteroidBlack) ? const Color(0xFFFFFFFF) : (isDark ? Colors.white : const Color(0xFF09090B));
    final labelColor = (type == AppThemeType.asteroidBlack) ? const Color(0xFFA1A1AA) : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A));
    final fillCol = (type == AppThemeType.asteroidBlack) ? const Color(0xFFE4E4E7).withValues(alpha: 0.1) : (isDark ? const Color(0xFF18181B).withValues(alpha: 0.5) : const Color(0xFFF4F4F5));

    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(color: labelColor),
      hintStyle: GoogleFonts.plusJakartaSans(color: labelColor.withValues(alpha: 0.7)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: defaultFocus, width: 2),
      ),
      filled: true,
      fillColor: fillCol,
    );
  }
}
