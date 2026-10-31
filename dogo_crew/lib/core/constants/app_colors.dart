import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF090A0F);
  static const Color surface = Color(0xFF131620);
  static const Color surfaceLight = Color(0xFF1C2030);
  static const Color surfaceElevated = Color(0xFF222738);

  // Borders & Dividers
  static const Color border = Color(0x1FFFFFFF);
  static const Color borderStrong = Color(0x33FFFFFF);

  // Brand Gradients & Colors
  static const Color brand = Color(0xFF3860F5);
  static const Color brandLight = Color(0xFF5A7FFF);
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF3860F5), Color(0xFF5A7FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gold / Accent
  static const Color gold = Color(0xFFF5A623);
  static const Color goldLight = Color(0xFFFFC043);
  static const Color goldBg = Color(0x1AF5A623);
  static const Color goldBorder = Color(0x4DF5A623);

  // Status & Semantic
  static const Color success = Color(0xFF2ECC71);
  static const Color successBg = Color(0x1A2ECC71);
  static const Color successBorder = Color(0x4D2ECC71);

  static const Color destructive = Color(0xFFE74C3C);
  static const Color destructiveBg = Color(0x1AE74C3C);
  static const Color destructiveBorder = Color(0x4DE74C3C);

  // Typography
  static const Color textPrimary = Color(0xFFF5F6FA);
  static const Color textSecondary = Color(0xFFA0A6B8);
  static const Color textMuted = Color(0xFF6B7285);
}
