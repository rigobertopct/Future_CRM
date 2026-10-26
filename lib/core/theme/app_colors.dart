import 'package:flutter/material.dart';

/// Paleta de la versión web del sistema (https://qainos.com), tomada de sus
/// variables CSS: `--bg`, `--surface`, `--surface-2`, `--border`, `--fg`,
/// `--muted`, `--primary`, `--warning(-soft)` y `--danger`.
///
/// [light] es `:root` y [dark] es `:root.dark`. El acento dorado de la marca
/// vive en [SidebarColors], igual que en la web.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
  });

  static const light = AppPalette(
    background: Color(0xFFF7F5EB),
    foreground: Color(0xFF22251F),
    card: Color(0xFFFFFEFA),
    cardForeground: Color(0xFF22251F),
    primary: Color(0xFF242424),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFF3F1E7),
    secondaryForeground: Color(0xFF22251F),
    muted: Color(0xFFF3F1E7),
    mutedForeground: Color(0xFF666A61),
    accent: Color(0xFFFFF5CC),
    accentForeground: Color(0xFFA87400),
    destructive: Color(0xFFD34D57),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFFE4E1D5),
  );

  static const dark = AppPalette(
    background: Color(0xFF111511),
    foreground: Color(0xFFF0F1E9),
    card: Color(0xFF191E19),
    cardForeground: Color(0xFFF0F1E9),
    primary: Color(0xFFE6E6E6),
    primaryForeground: Color(0xFF171717),
    secondary: Color(0xFF232923),
    secondaryForeground: Color(0xFFF0F1E9),
    muted: Color(0xFF232923),
    mutedForeground: Color(0xFFB2B8AD),
    accent: Color(0xFF332A12),
    accentForeground: Color(0xFFF0C64E),
    destructive: Color(0xFFF1848D),
    destructiveForeground: Color(0xFF35191C),
    border: Color(0xFF303830),
  );

  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;

  static AppPalette of(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>();
    assert(palette != null, 'AppPalette is missing from ThemeData.extensions');
    return palette!;
  }

  @override
  AppPalette copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? cardForeground,
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? destructiveForeground,
    Color? border,
  }) {
    return AppPalette(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      destructive: destructive ?? this.destructive,
      destructiveForeground:
          destructiveForeground ?? this.destructiveForeground,
      border: border ?? this.border,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: mix(background, other.background),
      foreground: mix(foreground, other.foreground),
      card: mix(card, other.card),
      cardForeground: mix(cardForeground, other.cardForeground),
      primary: mix(primary, other.primary),
      primaryForeground: mix(primaryForeground, other.primaryForeground),
      secondary: mix(secondary, other.secondary),
      secondaryForeground: mix(secondaryForeground, other.secondaryForeground),
      muted: mix(muted, other.muted),
      mutedForeground: mix(mutedForeground, other.mutedForeground),
      accent: mix(accent, other.accent),
      accentForeground: mix(accentForeground, other.accentForeground),
      destructive: mix(destructive, other.destructive),
      destructiveForeground: mix(
        destructiveForeground,
        other.destructiveForeground,
      ),
      border: mix(border, other.border),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppPalette &&
        background == other.background &&
        foreground == other.foreground &&
        card == other.card &&
        cardForeground == other.cardForeground &&
        primary == other.primary &&
        primaryForeground == other.primaryForeground &&
        secondary == other.secondary &&
        secondaryForeground == other.secondaryForeground &&
        muted == other.muted &&
        mutedForeground == other.mutedForeground &&
        accent == other.accent &&
        accentForeground == other.accentForeground &&
        destructive == other.destructive &&
        destructiveForeground == other.destructiveForeground &&
        border == other.border;
  }

  @override
  int get hashCode => Object.hash(
    background,
    foreground,
    card,
    cardForeground,
    primary,
    primaryForeground,
    secondary,
    secondaryForeground,
    muted,
    mutedForeground,
    accent,
    accentForeground,
    destructive,
    destructiveForeground,
    border,
  );
}

/// Barra lateral de la web: siempre oscura (también en modo claro) con el
/// dorado de la marca en el logo y en la sección activa.
abstract final class SidebarColors {
  static const Color top = Color(0xFF171B18);
  static const Color bottom = Color(0xFF121613);
  static const Color border = Color(0xFF292E29);
  static const Color foreground = Color(0xFFEEEFE8);
  static const Color muted = Color(0xFFAEB4AA);
  static const Color subtle = Color(0xFF858D82);
  static const Color surface = Color(0xFF20251F);
  static const Color activeStart = Color(0xFF29281C);
  static const Color activeEnd = Color(0xFF1D2119);
  static const Color activeForeground = Color(0xFFF5F4E9);
  static const Color brand = Color(0xFFF2C33A);
  static const Color brandForeground = Color(0xFF211A08);

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [top, bottom],
  );
}
