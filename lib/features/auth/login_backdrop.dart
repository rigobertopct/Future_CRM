import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Fondo animado del login: aurora, rejilla en perspectiva que avanza y una
/// constelación de nodos conectados (la red de contactos del CRM).
///
/// Todo se pinta en un solo [CustomPainter] que repinta con [ambient]; no
/// reconstruye widgets. [warp] (0→1) acelera la rejilla al entrar a la app.
/// Con "reducir movimiento" se pinta un solo fotograma fijo.
class LoginBackdrop extends StatelessWidget {
  const LoginBackdrop({super.key, required this.ambient, required this.warp});

  /// Ciclo continuo 0→1. Todas las trayectorias cierran en 1, así el bucle
  /// no salta.
  final Animation<double> ambient;
  final Animation<double> warp;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _BackdropPainter(ambient: ambient, warp: warp),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _Node {
  const _Node(this.x, this.y, this.fx, this.fy, this.phase, this.brand);

  final double x;
  final double y;
  final int fx;
  final int fy;
  final double phase;
  final bool brand;
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({required this.ambient, required this.warp})
    : super(repaint: Listenable.merge([ambient, warp]));

  final Animation<double> ambient;
  final Animation<double> warp;

  static const _gold = SidebarColors.brand;
  static const _green = Color(0xFF68CC91);
  static const _blue = Color(0xFF82B8F5);
  static const _ink = SidebarColors.foreground;

  /// Líneas horizontales de la rejilla que recorren el suelo en un ciclo.
  static const _gridRows = 14;
  static const _gridRowsPerCycle = 7;

  static final List<_Node> _nodes = _seedNodes();

  static List<_Node> _seedNodes() {
    final random = math.Random(7);
    return List.generate(38, (i) {
      return _Node(
        random.nextDouble(),
        random.nextDouble() * 0.72,
        1 + random.nextInt(2),
        1 + random.nextInt(2),
        random.nextDouble() * math.pi * 2,
        i % 6 == 0,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final a = ambient.value * math.pi * 2;
    final w = warp.value;
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B0E0B), Color(0xFF111511), Color(0xFF0D100D)],
        ).createShader(rect),
    );

    _aurora(canvas, size, a, w);
    _grid(canvas, size, w);
    _constellation(canvas, size, a, w);
    _vignette(canvas, rect);
  }

  void _aurora(Canvas canvas, Size size, double a, double w) {
    final span = math.max(size.width, size.height);
    void blob(Offset center, double radius, Color color, double alpha) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    blob(
      Offset(
        size.width * (0.22 + 0.10 * math.sin(a)),
        size.height * (0.22 + 0.06 * math.cos(2 * a)),
      ),
      span * 0.55,
      _gold,
      0.15 + 0.10 * w,
    );
    blob(
      Offset(
        size.width * (0.84 + 0.08 * math.cos(a)),
        size.height * (0.30 + 0.08 * math.sin(a)),
      ),
      span * 0.45,
      _green,
      0.09,
    );
    blob(
      Offset(size.width * (0.5 + 0.18 * math.sin(2 * a)), size.height * 0.95),
      span * 0.5,
      _blue,
      0.06,
    );
  }

  void _grid(Canvas canvas, Size size, double w) {
    final horizon = size.height * 0.64;
    final floor = Rect.fromLTRB(0, horizon, size.width, size.height);
    final vanish = Offset(size.width / 2, horizon);
    final fade = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _gold.withValues(alpha: 0),
        _gold.withValues(alpha: 0.16 + 0.22 * w),
      ],
    ).createShader(floor);
    final paint = Paint()
      ..shader = fade
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.clipRect(floor);

    // Líneas que convergen en el punto de fuga.
    const columns = 12;
    for (var i = -columns; i <= columns; i++) {
      final bottomX = size.width / 2 + i * size.width / 7;
      canvas.drawLine(vanish, Offset(bottomX, size.height), paint);
    }

    // Líneas horizontales que se acercan; con [w] avanzan más rápido.
    final cycle = ambient.value * _gridRowsPerCycle + w * 6;
    final phase = cycle - cycle.floorToDouble();
    for (var k = 0; k < _gridRows; k++) {
      final p = (k + phase) / _gridRows;
      final y = horizon + (size.height - horizon) * p * p;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.restore();
  }

  void _constellation(Canvas canvas, Size size, double a, double w) {
    final reach = math.min(size.width, size.height) * 0.2;
    final points = <Offset>[
      for (final n in _nodes)
        Offset(
          size.width * (n.x + 0.025 * math.sin(a * n.fx + n.phase)),
          size.height * (n.y + 0.025 * math.cos(a * n.fy + n.phase)),
        ),
    ];

    final line = Paint()..strokeWidth = 0.8;
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final d = (points[i] - points[j]).distance;
        if (d > reach) continue;
        final strength = 1 - d / reach;
        line.color = _ink.withValues(alpha: 0.14 * strength * (1 - w));
        canvas.drawLine(points[i], points[j], line);
      }
    }

    final dot = Paint();
    for (var i = 0; i < points.length; i++) {
      final n = _nodes[i];
      if (n.brand) {
        // Los nodos dorados "laten" a destiempo.
        final pulse = 0.5 + 0.5 * math.sin(a * 2 + n.phase);
        dot.color = _gold.withValues(alpha: 0.18 * pulse);
        canvas.drawCircle(points[i], 7 + 5 * pulse, dot);
        dot.color = _gold.withValues(alpha: 0.95);
        canvas.drawCircle(points[i], 2.2, dot);
      } else {
        dot.color = _ink.withValues(alpha: 0.45 * (1 - w * 0.6));
        canvas.drawCircle(points[i], 1.4, dot);
      }
    }
  }

  void _vignette(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
          stops: const [0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      oldDelegate.ambient != ambient || oldDelegate.warp != warp;
}
