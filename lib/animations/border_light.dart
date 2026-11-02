import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';

/// Reloj compartido del destello que recorre el borde de las tarjetas.
///
/// Un solo ticker para toda la app: cada [BorderLight] solo repinta su borde.
/// Con [enabled] en `false` o "reducir movimiento" no hay destello.
class BorderLightScope extends StatefulWidget {
  const BorderLightScope({super.key, this.enabled = true, required this.child});

  final bool enabled;
  final Widget child;

  /// Animación en curso, o `null` si el destello está apagado.
  static Animation<double>? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_BorderLightClock>()
      ?.animation;

  @override
  State<BorderLightScope> createState() => _BorderLightScopeState();
}

class _BorderLightScopeState extends State<BorderLightScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  bool get _running => widget.enabled && !AppMotion.reduced(context);

  void _sync() {
    if (_running) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(BorderLightScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _BorderLightClock(
    animation: _running ? _clock : null,
    child: widget.child,
  );
}

class _BorderLightClock extends InheritedWidget {
  const _BorderLightClock({required this.animation, required super.child});

  final Animation<double>? animation;

  @override
  bool updateShouldNotify(_BorderLightClock oldWidget) =>
      oldWidget.animation != animation;
}

/// Pinta el destello sobre el borde de [child] cuando hay un
/// [BorderLightScope] activo; si no, devuelve [child] tal cual.
class BorderLight extends StatelessWidget {
  const BorderLight({
    super.key,
    required this.radius,
    this.phase = 0,
    required this.child,
  });

  final double radius;

  /// Desfase (0–1) para que no todas las tarjetas brillen a la vez.
  final double phase;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = BorderLightScope.of(context);
    if (animation == null) return child;
    return CustomPaint(
      foregroundPainter: BorderLightPainter(
        animation: animation,
        radius: radius,
        phase: phase,
      ),
      // El contenido no se repinta en cada fotograma, solo el borde.
      child: RepaintBoundary(child: child),
    );
  }
}

/// Destello de color de marca que gira alrededor de un borde redondeado.
class BorderLightPainter extends CustomPainter {
  BorderLightPainter({
    required this.animation,
    required this.radius,
    this.phase = 0,
    this.turns = 1,
    this.baseColor,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final double radius;
  final double phase;

  /// Vueltas completas por ciclo de [animation].
  final int turns;

  /// Si se indica, también pinta el borde fijo debajo del destello.
  final Color? baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    if (baseColor != null) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = baseColor!,
      );
    }
    final angle = (animation.value * turns + phase) * math.pi * 2;
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = SweepGradient(
          colors: [
            SidebarColors.brand.withValues(alpha: 0),
            SidebarColors.brand.withValues(alpha: 0.9),
            SidebarColors.brand.withValues(alpha: 0),
            SidebarColors.brand.withValues(alpha: 0),
          ],
          stops: const [0, 0.08, 0.18, 1],
          transform: GradientRotation(angle),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(BorderLightPainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.radius != radius ||
      oldDelegate.phase != phase ||
      oldDelegate.turns != turns ||
      oldDelegate.baseColor != baseColor;
}
