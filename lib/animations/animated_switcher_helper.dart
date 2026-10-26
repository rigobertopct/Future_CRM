import 'package:flutter/material.dart';

/// Fundido cruzado al reemplazar [child].
///
/// Cambia [switchKey] cuando el contenido cambia de verdad (otra pestaña,
/// otro estado de carga, otro filtro). Si la clave no cambia, el hijo se
/// actualiza en el sitio y no se anima.
///
/// ```dart
/// AnimatedSwitcherHelper(
///   switchKey: tab,
///   child: tab == 0 ? Formulario() : Resumen(),
/// )
/// ```
class AnimatedSwitcherHelper extends StatelessWidget {
  const AnimatedSwitcherHelper({
    super.key,
    required this.switchKey,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
  });

  final Object switchKey;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) {
        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [...previous, ?current],
        );
      },
      child: KeyedSubtree(key: ValueKey<Object>(switchKey), child: child),
    );
  }
}
