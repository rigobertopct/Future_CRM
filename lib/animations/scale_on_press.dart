import 'package:flutter/material.dart';

/// Reduce un poco la escala mientras el dedo está apoyado.
///
/// No captura el toque: el botón o la tarjeta de dentro siguen recibiendo
/// `onPressed`. Envuelve el control completo, y deja la [Key] en el hijo.
///
/// ```dart
/// ScaleOnPress(
///   child: FilledButton(onPressed: save, child: Text('Guardar')),
/// )
/// ```
class ScaleOnPress extends StatefulWidget {
  const ScaleOnPress({
    super.key,
    required this.child,
    this.scale = 0.96,
    this.duration = const Duration(milliseconds: 120),
  });

  final Widget child;
  final double scale;
  final Duration duration;

  @override
  State<ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<ScaleOnPress> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
