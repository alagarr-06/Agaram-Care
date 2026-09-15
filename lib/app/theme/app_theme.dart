import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF0B6E69);
  static const Color background = Color(0xFFF6F8F7);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF17201F);
  static const Color textSecondary = Color(0xFF65716F);
  static const Color border = Color(0xFFE0E6E4);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkBackground = Color(0xFF101514);
    const darkSurface = Color(0xFF18201F);
    const darkText = Color(0xFFF1F5F4);
    const darkSecondary = Color(0xFFB8C4C1);
    const darkBorder = Color(0xFF35413F);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF4DB6AE),
        onPrimary: Colors.black,
        surface: darkSurface,
        onSurface: darkText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkText,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: darkText),
        bodyMedium: TextStyle(color: darkSecondary),
        titleLarge: TextStyle(color: darkText),
        titleMedium: TextStyle(color: darkText),
        headlineSmall: TextStyle(color: darkText),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF15958C),
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        labelStyle: const TextStyle(color: darkSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF4DB6AE),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
