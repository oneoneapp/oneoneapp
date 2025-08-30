import 'package:flutter/material.dart';

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
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkColorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: _darkColorScheme.primary,
          width: 1,
        ),
      ),
      hintStyle: TextStyle(
        color: _darkColorScheme.onSurface.withAlpha(100),
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: _darkColorScheme.primary,
          width: 2.5,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 18,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: _darkColorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: _darkColorScheme.onSurface,
      ),
    ),
  );
}