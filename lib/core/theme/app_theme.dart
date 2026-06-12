import 'package:flutter/material.dart';
import 'color_palette.dart';

/// مجلد: core/theme
/// يحتوي على إعدادات التصميم الخاص بالتطبيق (الثيمات والألوان).
/// 
/// ملف: app_theme.dart
/// يحدد الثيمات الخاصة بالتطبيق (مثل الثيم الفاتح والداكن) وتنسيقات النصوص والـ AppBar وغيرها.
class AppTheme {
  // ----------------- الوضع النهاري (Light Theme) -----------------
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: ColorPalette.primaryColor,
      scaffoldBackgroundColor: ColorPalette.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: ColorPalette.primaryColor,
        secondary: ColorPalette.secondaryColor,
        surface: ColorPalette.surfaceLight,
        error: ColorPalette.errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: ColorPalette.textPrimaryLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ColorPalette.textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: ColorPalette.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: ColorPalette.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorPalette.primaryColor,
          side: const BorderSide(color: ColorPalette.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorPalette.primaryColor,
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(ColorPalette.tableHeaderLight),
        headingTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        dataTextStyle: const TextStyle(
          color: ColorPalette.textPrimaryLight,
          fontSize: 13,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ColorPalette.surfaceLight,
        selectedColor: ColorPalette.primaryColor.withValues(alpha: 0.15),
        labelStyle: const TextStyle(fontSize: 13),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColorPalette.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: ColorPalette.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 32),
        headlineLarge: TextStyle(color: ColorPalette.textPrimaryLight, fontWeight: FontWeight.w700, fontSize: 24),
        headlineMedium: TextStyle(color: ColorPalette.textPrimaryLight, fontWeight: FontWeight.w600, fontSize: 20),
        titleLarge: TextStyle(color: ColorPalette.textPrimaryLight, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(color: ColorPalette.textPrimaryLight, fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge: TextStyle(color: ColorPalette.textPrimaryLight, fontSize: 16),
        bodyMedium: TextStyle(color: ColorPalette.textSecondaryLight, fontSize: 14),
        bodySmall: TextStyle(color: ColorPalette.textSecondaryLight, fontSize: 12),
        labelLarge: TextStyle(color: ColorPalette.textPrimaryLight, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorPalette.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorPalette.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorPalette.errorColor, width: 2),
        ),
        labelStyle: const TextStyle(color: ColorPalette.textSecondaryLight),
        hintStyle: TextStyle(color: ColorPalette.textSecondaryLight.withValues(alpha: 0.7)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: ColorPalette.textSecondaryLight,
      ),
    );
  }

  // ----------------- الوضع الليلي (Dark Theme) -----------------
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: ColorPalette.primaryColorDarkMode,
      scaffoldBackgroundColor: ColorPalette.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: ColorPalette.primaryColorDarkMode,
        secondary: ColorPalette.secondaryColorDarkMode,
        surface: ColorPalette.surfaceDark,
        error: ColorPalette.errorColor,
        onPrimary: Colors.white,
        onSecondary: ColorPalette.backgroundDark,
        onSurface: ColorPalette.textPrimaryDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorPalette.surfaceDark,
        foregroundColor: ColorPalette.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: ColorPalette.textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: ColorPalette.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primaryColorDarkMode,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorPalette.primaryColorDarkMode,
          side: const BorderSide(color: ColorPalette.primaryColorDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorPalette.primaryColorDarkMode,
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(ColorPalette.tableHeaderDark),
        headingTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        dataTextStyle: const TextStyle(
          color: ColorPalette.textPrimaryDark,
          fontSize: 13,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ColorPalette.surfaceDark,
        selectedColor: ColorPalette.primaryColorDarkMode.withValues(alpha: 0.2),
        labelStyle: const TextStyle(fontSize: 13),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColorPalette.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: ColorPalette.textPrimaryDark, fontWeight: FontWeight.bold, fontSize: 32),
        headlineLarge: TextStyle(color: ColorPalette.textPrimaryDark, fontWeight: FontWeight.w700, fontSize: 24),
        headlineMedium: TextStyle(color: ColorPalette.textPrimaryDark, fontWeight: FontWeight.w600, fontSize: 20),
        titleLarge: TextStyle(color: ColorPalette.textPrimaryDark, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(color: ColorPalette.textPrimaryDark, fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge: TextStyle(color: ColorPalette.textPrimaryDark, fontSize: 16),
        bodyMedium: TextStyle(color: ColorPalette.textSecondaryDark, fontSize: 14),
        bodySmall: TextStyle(color: ColorPalette.textSecondaryDark, fontSize: 12),
        labelLarge: TextStyle(color: ColorPalette.textPrimaryDark, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorPalette.primaryColorDarkMode, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorPalette.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorPalette.errorColor, width: 2),
        ),
        labelStyle: const TextStyle(color: ColorPalette.textSecondaryDark),
        hintStyle: TextStyle(color: ColorPalette.textSecondaryDark.withValues(alpha: 0.7)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: ColorPalette.textSecondaryDark,
      ),
    );
  }
}
