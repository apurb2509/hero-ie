import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryNeon = Color(0xFF00FFCC); // Neon Cyan
  static const Color backgroundMatte = Color(0xFF121212); // Matte Black
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color errorNeon = Color(0xFFFF3366); // Neon Red/Pink for SOS
  static const Color warningNeon = Color(0xFFFFCC00); // Neon Yellow

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

  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryNeon),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
    );
  }
}
