import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF6C63FF); // Modern Indigo
  static const Color primaryVariant = Color(0xFF4A41E0);

  // Secondary Palette
  static const Color secondary = Color(0xFF03DAC6); // Teal
  static const Color secondaryVariant = Color(0xFF018786);

  // Backgrounds
  static const Color background = Color(0xFF121212); // Dark Material Background
  static const Color surface = Color(0xFF1E1E1E); // Slightly lighter for Cards

  // Status Colors
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Text Colors
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black;
  static const Color onBackground = Color(0xFFE0E0E0); // Off-white for text
  static const Color onSurface = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFFAAAAAA); // Muted text

  // UI Accents
  static const Color divider = Color(0xFF2C2C2C);
  static const Color inputField = Color(0xFF2C2C2C);
}
