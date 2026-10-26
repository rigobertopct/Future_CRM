import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Spinner de un solo color centrado en pantalla.
///
/// Continúa la splash nativa de Android 12+ (`splash_icon.xml` y
/// `splash_spin.xml`): mismo fondo, tamaño, trazo, arco de 270° y giro lineal
/// de 1 s. Si cambias uno, cambia el otro para que el relevo no se note.
/// Los colores son fijos porque la splash nativa no conoce el tema de la app.
/// Quítalo del árbol en cuanto haya contenido: la animación se repite
/// mientras el widget está montado.
class RoamingSpinner extends StatefulWidget {
  const RoamingSpinner({super.key});

  @override
  State<RoamingSpinner> createState() => _RoamingSpinnerState();
}

class _RoamingSpinnerState extends State<RoamingSpinner>
    with SingleTickerProviderStateMixin {
  static const _background = Color(0xFF111511);
  static const _accent = Color(0xFFF2C33A);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: Center(
        child: Semantics(
          label: 'Cargando',
          child: RepaintBoundary(
            child: CustomPaint(
              size: const Size.square(44),
              painter: _ArcPainter(
                animation: _controller,
                color: _accent,
                track: _accent.withValues(alpha: 0.16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.animation,
    required this.color,
    required this.track,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final Color track;

  static const _strokeWidth = 4.0;
  static const _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_strokeWidth / 2);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _strokeWidth
      ..color = color;
    canvas.drawArc(
      rect,
      -math.pi / 2 + animation.value * math.pi * 2,
      _sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.color != color || old.track != track;
}
