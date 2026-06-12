import 'package:flutter/material.dart';

/// مجلد: core/theme
/// 
/// ملف: color_palette.dart
/// يحتوي على ثوابت الألوان المستخدمة في التطبيق لسهولة تغييرها وتوحيدها.
class ColorPalette {
  // ──────────────── الألوان الأساسية (Primary Colors) ────────────────
  // الوضع النهاري
  static const Color primaryColor = Color(0xFFFF6B00);
  static const Color primaryDark = Color(0xFFE05E00);
  static const Color primaryLight = Color(0xFFFF8C42);

  // الوضع الليلي
  static const Color primaryColorDarkMode = Color(0xFFFF8C42);

  // ──────────────── الألوان الثانوية (Secondary Colors) ────────────────
  static const Color secondaryColor = Color(0xFF1A1A1A);
  static const Color secondaryColorDarkMode = Color(0xFFFFFFFF);

  // ──────────────── ألوان الخلفية - الوضع النهاري (Light Mode) ────────────────
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Colors.white;
  static const Color cardLight = Colors.white;

  // ──────────────── ألوان الخلفية - الوضع الليلي (Dark Mode) ────────────────
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF252525);

  // ──────────────── ألوان النصوص (Text Colors) ────────────────
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF757575);

  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // ──────────────── ألوان الحالات (Status Colors) ────────────────
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF3B82F6);

  // ──────────────── ألوان إضافية للـ Gym Theme ────────────────
  static const Color activeStatus = Color(0xFF22C55E);
  static const Color expiredStatus = Color(0xFFEF4444);
  static const Color expiringSoonStatus = Color(0xFFF59E0B);
  static const Color debtStatus = Color(0xFFE11D48);

  // ──────────────── ألوان DataTable ────────────────
  static const Color tableHeaderLight = Color(0xFF1A1A1A);
  static const Color tableRowEvenLight = Color(0xFFFFFFFF);
  static const Color tableRowOddLight = Color(0xFFFAFAFA);

  static const Color tableHeaderDark = Color(0xFF2A2A2A);
  static const Color tableRowEvenDark = Color(0xFF1E1E1E);
  static const Color tableRowOddDark = Color(0xFF252525);
}
