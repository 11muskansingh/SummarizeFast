import 'package:flutter/material.dart';

/// App color palette with dark theme support
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2563EB); // Blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E40AF);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF8B5CF6); // Purple
  static const Color secondaryLight = Color(0xFFA78BFA);
  
  // Accent Colors
  static const Color accent = Color(0xFF10B981); // Green
  static const Color accentWarning = Color(0xFFF59E0B); // Orange
  static const Color accentError = Color(0xFFEF4444); // Red
  
  // Surface Colors (Dark Theme)
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFF2A2A2A);
  static const Color surfaceDark = Color(0xFF171717);
  static const Color background = Color(0xFF121212);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE0E0E0);
  static const Color textTertiary = Color(0xFFB0B0B0);
  static const Color textDisabled = Color(0xFF757575);
  
  // Border & Divider
  static const Color border = Color(0xFF3A3A3A);
  static const Color divider = Color(0xFF2A2A2A);
  
  // Glassmorphism
  static const Color glassLight = Color(0x1AFFFFFF); // 10% white
  static const Color glassMedium = Color(0x33FFFFFF); // 20% white
  static const Color glassDark = Color(0x0DFFFFFF); // 5% white
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surfaceLight, surfaceDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient glassGradient = LinearGradient(
    colors: [glassLight, glassDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
