import 'package:flutter/material.dart';

/// Duraciones y curvas compartidas por todas las animaciones de la app.
///
/// Un solo ritmo: entradas con curva exponencial de salida (rápido al inicio,
/// asentamiento largo) y salidas más cortas que las entradas.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 280);
  static const Duration view = Duration(milliseconds: 420);

  /// Entrada: arranque brusco y frenado suave (expo-out).
  static const Curve out = Cubic(0.16, 1, 0.3, 1);

  /// Salida: arranque suave y cierre rápido.
  static const Curve exit = Cubic(0.7, 0, 0.84, 0);

  /// `true` cuando el sistema pide reducir el movimiento.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Ritmo de las hojas modales: entran con la curva de entrada de la app y
  /// salen más rápido. Con "reducir movimiento" no animan.
  static AnimationStyle sheet(BuildContext context) => reduced(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(
          duration: Duration(milliseconds: 380),
          reverseDuration: Duration(milliseconds: 240),
          curve: out,
          reverseCurve: exit,
        );
}
