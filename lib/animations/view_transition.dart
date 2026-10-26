import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';

/// Transición entre vistas principales (secciones del menú).
///
/// Usa el eje compartido horizontal de Material (`SharedAxisTransition`): la
/// vista nueva entra desde el lado hacia el que avanza el menú y la anterior
/// sale hacia el contrario, con fundido. Un barrido de luz esmeralda cruza la pantalla una sola vez para marcar el
/// cambio. Solo anima `transform` y `opacity`.
///
/// [index] decide la dirección: un valor mayor avanza, uno menor retrocede.
/// Con "reducir movimiento" activo el cambio es instantáneo y sin barrido.
///
/// ```dart
/// ViewTransition(
///   index: section.index,
///   child: pageFor(section),
/// )
/// ```
class ViewTransition extends StatefulWidget {
  const ViewTransition({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<ViewTransition> createState() => _ViewTransitionState();
}

class _ViewTransitionState extends State<ViewTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  );
  int _direction = 1;

  @override
  void didUpdateWidget(ViewTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    _direction = widget.index > oldWidget.index ? 1 : -1;
    if (!AppMotion.reduced(context)) _sweep.forward(from: 0);
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final color = AppPalette.of(context).primary;
    final key = ValueKey<int>(widget.index);

    return Stack(
      fit: StackFit.expand,
      children: [
        PageTransitionSwitcher(
          duration: reduced ? Duration.zero : AppMotion.view,
          reverse: _direction < 0,
          layoutBuilder: (entries) =>
              Stack(fit: StackFit.expand, children: entries),
          transitionBuilder: (child, animation, secondaryAnimation) =>
              SharedAxisTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.horizontal,
                fillColor: Colors.transparent,
                child: child,
              ),
          child: KeyedSubtree(key: key, child: widget.child),
        ),
        IgnorePointer(
          child: ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _sweep,
              builder: (context, _) {
                if (_sweep.status != AnimationStatus.forward) {
                  return const SizedBox.shrink();
                }
                return CustomPaint(
                  painter: _SweepPainter(
                    progress: Curves.easeInOutCubic.transform(_sweep.value),
                    color: color,
                    direction: _direction,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SweepPainter extends CustomPainter {
  const _SweepPainter({
    required this.progress,
    required this.color,
    required this.direction,
  });

  final double progress;
  final Color color;
  final int direction;

  @override
  void paint(Canvas canvas, Size size) {
    final band = size.width * 0.32;
    // Avanzar = la luz viaja hacia la izquierda, igual que el contenido.
    final travel = size.width + band * 2;
    final head = direction > 0
        ? size.width + band - travel * progress
        : -band + travel * progress;
    final rect = Rect.fromLTWH(head - band / 2, 0, band, size.height);
    final fade = 1 - (progress - 0.5).abs() * 2; // sube y baja una vez
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: 0.16 * fade),
            color.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SweepPainter old) =>
      old.progress != progress || old.color != color;
}
