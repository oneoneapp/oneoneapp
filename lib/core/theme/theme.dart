import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Themes {
  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.yellow,
    brightness: Brightness.dark
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.yellow,
    colorScheme: _darkColorScheme,
    scaffoldBackgroundColor: Colors.black,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    inputDecorationTheme: inputDecorationTheme(_darkColorScheme),
    textTheme: textTheme(_darkColorScheme),
  );

  static InputDecorationTheme inputDecorationTheme(ColorScheme scheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: scheme.primary,
          width: 1,
        ),
      ),
      hintStyle: TextStyle(
        color: scheme.onSurface.withAlpha(100),
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: scheme.primary,
          width: 2.5,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 18,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }

  static TextTheme textTheme(ColorScheme scheme) {
    return TextTheme(
      // Splash / big branding
      displayLarge: GoogleFonts.teko(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: scheme.onSurface,
      ),

      // Secondary big headings (intro screens / onboarding titles)
      displayMedium: GoogleFonts.teko(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: scheme.onSurface,
      ),

      // Used in dialogs / large in-app headings
      displaySmall: GoogleFonts.teko(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: scheme.onSurface,
      ),

      // Section titles, app bar titles
      headlineLarge: GoogleFonts.teko(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: scheme.onSurface,
      ),

      // Sub-section headers
      headlineMedium: GoogleFonts.teko(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: scheme.onSurface,
      ),

      // Minor headings
      headlineSmall: GoogleFonts.teko(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),

      // Titles for dialogs/cards
      titleLarge: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),

      // AppBar / list tile primary title
      titleMedium: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),

      // Chip/mini title
      titleSmall: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),

      // Main body text
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: scheme.onSurface,
      ),

      // Secondary body text / subtitles
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: scheme.onSurface.withValues(alpha: 0.87),
      ),

      // Tertiary body (caption-like text under messages)
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface.withValues(alpha: 0.6),
      ),

      // Buttons / interactive labels
      labelLarge: GoogleFonts.teko(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: scheme.primary,
      ),

      // Small labels (chip text, input helpers)
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: scheme.onSurface,
      ),

      // Very tiny labels
      labelSmall: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}