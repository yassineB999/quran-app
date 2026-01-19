import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryTeal = Color(0xFF00695C); // Premium Teal
  static const Color goldAccent = Color(0xFFD4AF37); // Gold

  static const Color warmBeige = Color(0xFFF8F5F2); // Warm Beige
  static const Color warmGreen = Color(0xFF2D6A4F); // Warm Green

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFFFFFF); // Pure White
  static const Color lightSurface = Color(
    0xFFF5F7F6,
  ); // Very subtle cool grey for cards
  static const Color lightTextPrimary = Color(0xFF1A1A1A); // Almost Black
  static const Color lightTextSecondary = Color(0xFF757575); // Grey

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0D1F1F); // Deep Teal Dark
  static const Color darkSurface = Color(0xFF1A3A3A); // Lighter Teal Surface
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0BEC5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: warmBeige, // Updated to Warm Beige
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        brightness: Brightness.light,
        primary: primaryTeal,
        secondary: goldAccent,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        background: warmBeige, // Updated to Warm Beige
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: lightTextPrimary),
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      fontFamily: 'Inter',
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        brightness: Brightness.dark,
        primary: primaryTeal, // Or TealAccent for contrast
        secondary: goldAccent,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        background: darkBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground, // Blend with body
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      fontFamily: 'Inter',
    );
  }
}
