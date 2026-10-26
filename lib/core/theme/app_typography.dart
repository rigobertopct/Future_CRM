import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Type scale shared with the web version (https://qainos.com).
///
/// UI text is Manrope. Codes, ids, and tabular figures use Geist Mono.
/// Sizes follow the site's Tailwind scale (16px root): xs 12, sm 14,
/// base 16, lg 18, xl 20, 2xl 24, 3xl 30, 4xl 36, 5xl 48.
abstract final class AppTypography {
  static const String sansFamily = 'Manrope';
  static const String monoFamily = 'Geist Mono';

  static TextTheme textTheme() {
    TextStyle sans({
      required double fontSize,
      required double height,
      required FontWeight fontWeight,
    }) {
      return GoogleFonts.manrope(
        fontSize: fontSize,
        height: height,
        fontWeight: fontWeight,
      );
    }

    return TextTheme(
      displayLarge: sans(fontSize: 48, height: 1, fontWeight: FontWeight.w700),
      displayMedium: sans(
        fontSize: 36,
        height: 40 / 36,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: sans(
        fontSize: 30,
        height: 36 / 30,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: sans(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: sans(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: sans(
        fontSize: 18,
        height: 28 / 18,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: sans(fontSize: 16, height: 1.25, fontWeight: FontWeight.w600),
      titleMedium: sans(
        fontSize: 14,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: sans(fontSize: 12, height: 1.25, fontWeight: FontWeight.w500),
      bodyLarge: sans(fontSize: 16, height: 1.5, fontWeight: FontWeight.w400),
      bodyMedium: sans(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: sans(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: sans(fontSize: 14, height: 1.25, fontWeight: FontWeight.w500),
      labelMedium: sans(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: sans(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static TextStyle mono({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    double height = 20 / 14,
    Color? color,
  }) {
    return GoogleFonts.geistMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );
  }
}
