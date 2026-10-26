import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Material theme wired to the qainos.com palette and type scale.
abstract final class AppTheme {
  /// `--radius: .625rem` (10px at a 16px root).
  static const double radius = 10;

  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      primary: palette.primary,
      onPrimary: palette.primaryForeground,
      secondary: palette.secondary,
      onSecondary: palette.secondaryForeground,
      tertiary: palette.accent,
      onTertiary: palette.accentForeground,
      error: palette.destructive,
      onError: palette.destructiveForeground,
      surface: palette.background,
      onSurface: palette.foreground,
      surfaceContainerLowest: palette.card,
      surfaceContainerLow: palette.card,
      surfaceContainer: palette.muted,
      surfaceContainerHigh: palette.secondary,
      surfaceContainerHighest: palette.muted,
      onSurfaceVariant: palette.mutedForeground,
      outline: palette.border,
      outlineVariant: palette.border,
      inverseSurface: palette.foreground,
      onInverseSurface: palette.background,
      inversePrimary: brightness == Brightness.light
          ? AppPalette.dark.primary
          : AppPalette.light.primary,
      surfaceTint: palette.primary,
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final textTheme = AppTypography.textTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: [palette],
      scaffoldBackgroundColor: palette.background,
      fontFamily: GoogleFonts.manrope().fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      dividerColor: palette.border,
      focusColor: palette.primary.withValues(alpha: 0.24),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: palette.foreground,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape.copyWith(side: BorderSide(color: palette.border)),
      ),
      dialogTheme: DialogThemeData(backgroundColor: palette.card, shape: shape),
      dividerTheme: DividerThemeData(color: palette.border, space: 1),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: palette.background,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: palette.mutedForeground,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: palette.foreground),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.primaryForeground,
          textStyle: textTheme.labelLarge,
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.foreground,
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: palette.border),
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: textTheme.labelLarge,
          shape: shape,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: palette.primaryForeground,
        shape: shape,
      ),
    );
  }
}
