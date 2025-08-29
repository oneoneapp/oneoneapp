import 'package:flutter/material.dart';

class Themes {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.yellow,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.yellow,
      brightness: Brightness.dark
    ),
    scaffoldBackgroundColor: Colors.black,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}