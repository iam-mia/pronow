import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotionColors {
  // Base Notion Paper Palette
  static const Color background = Color(0xFFFBFBFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF7F6F3);
  static const Color border = Color(0xFFEBEAE8);
  static const Color borderSubtle = Color(0xFFF1F1EF);
  
  // Typography
  static const Color textMain = Color(0xFF37352F);
  static const Color textMuted = Color(0xFF787774);
  static const Color textTertiary = Color(0xFF9B9A97);

  // Notion Pastel Tag System
  static const Color tagGreenBg = Color(0xFFEDF6EE);
  static const Color tagGreenText = Color(0xFF2A673B);
  
  static const Color tagAmberBg = Color(0xFFFDF5E6);
  static const Color tagAmberText = Color(0xFF9A6700);

  static const Color tagRedBg = Color(0xFFFDECE9);
  static const Color tagRedText = Color(0xFFC4362A);

  static const Color tagBlueBg = Color(0xFFE8F3FA);
  static const Color tagBlueText = Color(0xFF2E6B9E);

  static const Color tagGreyBg = Color(0xFFF1F1EF);
  static const Color tagGreyText = Color(0xFF5A5955);
}

class NotionTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: NotionColors.background,
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        surface: NotionColors.surface,
        onSurface: NotionColors.textMain,
        primary: NotionColors.textMain,
        outline: NotionColors.border,
      ),
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: NotionColors.textMain,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: NotionColors.textMain,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: NotionColors.textMain,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: NotionColors.textMain,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: NotionColors.textMuted,
          height: 1.4,
        ),
        labelSmall: GoogleFonts.robotoMono(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: NotionColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: NotionColors.textMain),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: NotionColors.textMain,
        ),
      ),
    );
  }
}
