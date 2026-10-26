import 'package:flutter/material.dart';

/// Efectos de luz reutilizables. Se usan solo en elementos activos o de
/// acción principal, nunca como decoración general.
abstract final class AppEffects {
  /// Halo suave alrededor de [color]. [strength] escala la opacidad.
  static List<BoxShadow> glow(Color color, {double strength = 1}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.28 * strength),
        blurRadius: 16,
        spreadRadius: -2,
      ),
    ];
  }
}
