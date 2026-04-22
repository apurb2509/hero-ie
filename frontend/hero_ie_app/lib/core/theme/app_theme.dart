import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryNeon = Color(0xFF00FFCC); // Neon Cyan
  static const Color secondaryNeon = Color(0xFFBD00FF); // Neon Purple
  static const Color backgroundMatte = Color(0xFF121212); // Matte Black
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color errorNeon = Color(0xFFFF3366); // Neon Red/Pink for SOS
  static const Color warningNeon = Color(0xFFFFCC00); // Neon Yellow

  // Light theme colors
  static const Color backgroundLight = Color(0xFFF4F6F8); // Very soft grey/off-white
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure white for cards in light mode

  // Global Theme Notifier for easy toggling
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundMatte,
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        surface: surfaceColor,
        error: errorNeon,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        bodyLarge: GoogleFonts.outfit(color: Colors.white70),
        bodyMedium: GoogleFonts.outfit(color: Colors.white70),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNeon,
          foregroundColor: backgroundMatte,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundMatte,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryNeon),
      ),
    );
  }

  static ThemeData get lightTheme {
    // slightly darker neons for better contrast on light backgrounds if needed,
    // but the cyans and dark purples usually work nicely with soft grey.
    final Color textDark = Colors.grey.shade900;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF00796B), // Deeper teal/cyan for excellent visibility
        surface: surfaceLight,
        error: errorNeon,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textDark),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textDark),
        bodyLarge: GoogleFonts.outfit(color: Colors.blueGrey.shade800),
        bodyMedium: GoogleFonts.outfit(color: Colors.blueGrey.shade800),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00897B), // Slightly more vibrant for filled buttons
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: textDark, // Text color
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF00796B)),
      ),
    );
  }

  static InputDecoration inputDecoration(String label, {Color? focusColor, bool isLightMode = false}) {
    final defaultFocus = focusColor ?? (isLightMode ? const Color(0xFF00796B) : primaryNeon);
    final borderColor = isLightMode ? Colors.blueGrey.shade200 : Colors.white.withOpacity(0.1);
    final labelColor = isLightMode ? Colors.blueGrey.shade600 : Colors.white70;
    final fillCol = isLightMode ? Colors.white : Colors.white.withOpacity(0.05);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelColor),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: defaultFocus),
      ),
      filled: true,
      fillColor: fillCol,
    );
  }
}
