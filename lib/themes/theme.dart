import 'dart:ui';

import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      // seedColor: const Color(0xFF2E7D32), // Premium Green
      primary: const Color(0xFF2E7D32),
      secondary: const Color(0xFF81C784),
      brightness: Brightness.light,
      seedColor: Colors.blue,
      surfaceContainer: Colors.red,
    ),
    useMaterial3: true,
    fontFamily: 'Roboto',
    // Modern font
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black87,
      centerTitle: true,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      primary: const Color(0xFF81C784),
      secondary: const Color(0xFFA5D6A7),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    fontFamily: 'Roboto',

    scaffoldBackgroundColor: const Color(0xFF121212),
    //Colors.black26,//const Color(Colors.black26), //Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),

    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF81C784), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
