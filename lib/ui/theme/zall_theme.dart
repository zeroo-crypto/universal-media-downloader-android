import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ZallTheme {
  // Brand Dark Blue Palette
  static const Color background = Color(0xFF141417);
  static const Color cardSurface = Color(0xFF202129);
  static const Color circleSurface = Color(0xFF14151B);
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color actionBlue = Color(0xFF2563EB);
  static const Color highlightBlue = Color(0xFF60A5FA);
  static const Color dividerColor = Color(0xFF2E303C);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E99);
  static const Color textMuted = Color(0xFF9E9EA7);
  static const Color errorRed = Color(0xFFEF4444);

  // Platform Brand Colors
  static const Color youtubeRed = Color(0xFFFF0000);
  static const Color pixivBlue = Color(0xFF0096FA);
  static const Color instagramGradientStart = Color(0xFFFDBA74);
  static const Color instagramGradientMiddle = Color(0xFFE1306C);
  static const Color instagramGradientEnd = Color(0xFF833AB4);
  static const Color pinterestRed = Color(0xFFE60023);
  static const Color tiktokBlack = Color(0xFF000000);
  static const Color twitterBlack = Color(0xFF0F1419);

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final poppinsTheme = GoogleFonts.poppinsTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: highlightBlue,
        surface: cardSurface,
        background: background,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      cardTheme: CardTheme(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
      ),
      textTheme: poppinsTheme.copyWith(
        headlineMedium: poppinsTheme.headlineMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: poppinsTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: poppinsTheme.titleMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: poppinsTheme.bodyLarge?.copyWith(
          color: textPrimary,
        ),
        bodyMedium: poppinsTheme.bodyMedium?.copyWith(
          color: textSecondary,
        ),
        bodySmall: poppinsTheme.bodySmall?.copyWith(
          color: textSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF1C1D26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1C1D26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
        ),
      ),
    );
  }
}
