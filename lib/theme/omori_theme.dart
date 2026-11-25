import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OmoriColors {
  static const Color whiteSpace = Color(0xFFFAFAFA);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF111111);
  static const Color mutedInk = Color(0xFF5C5C5C);
  static const Color subtleLine = Color(0xFFE3E3E3);
  static const Color redAccent = Color(0xFFC83737);
  static const Color dreamIndigo = Color(0xFF5363D6);
  static const Color pastelLavender = Color(0xFFF3F2FF);
  static const Color warmPaper = Color(0xFFFDFBF6);
}

class OmoriTheme {
  static bool useSystemFallbackFonts = false;

  static TextStyle hand({
    double size = 18,
    FontWeight weight = FontWeight.w400,
    Color color = OmoriColors.ink,
    double? height,
    double? letterSpacing,
  }) {
    if (useSystemFallbackFonts) {
      return TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height ?? 1.35,
        letterSpacing: letterSpacing,
      );
    }
    return GoogleFonts.patrickHand(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height ?? 1.35,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle pixel({
    double size = 18,
    Color color = OmoriColors.ink,
    double? letterSpacing,
  }) {
    if (useSystemFallbackFonts) {
      return TextStyle(
        fontFamily: 'monospace',
        fontSize: size,
        color: color,
        letterSpacing: letterSpacing ?? 0.8,
      );
    }
    return GoogleFonts.vt323(
      fontSize: size,
      color: color,
      letterSpacing: letterSpacing ?? 0.8,
    );
  }

  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: OmoriColors.whiteSpace,
      colorScheme: const ColorScheme.light(
        surface: OmoriColors.whiteSpace,
        primary: OmoriColors.ink,
        secondary: OmoriColors.dreamIndigo,
        error: OmoriColors.redAccent,
        onSurface: OmoriColors.ink,
        onPrimary: OmoriColors.paper,
      ),
      textTheme: TextTheme(
        headlineMedium: hand(size: 30, weight: FontWeight.w600),
        titleLarge: hand(size: 24, weight: FontWeight.w600),
        titleMedium: hand(size: 20, weight: FontWeight.w600),
        bodyLarge: hand(size: 18),
        bodyMedium: hand(size: 16),
        labelLarge: pixel(size: 20),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OmoriColors.paper,
        hintStyle: hand(size: 16, color: OmoriColors.mutedInk),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: OmoriColors.ink, width: 2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: OmoriColors.ink, width: 2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: OmoriColors.dreamIndigo, width: 2.5),
        ),
      ),
    );
  }
}
