import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_motion.dart';

/// Hace aparecer [child] de opacidad 0 a 1, con un leve deslizamiento hacia arriba.
///
/// Úsalo alrededor de cualquier widget. [delay] sirve para encadenar varios
/// `FadeInWidget` y armar una cascada sin un contenedor extra.
///
/// ```dart
/// FadeInWidget(child: Text('Hola'))
/// FadeInWidget(delay: Duration(milliseconds: 80), child: TextField())
/// ```
class FadeInWidget extends StatefulWidget {
  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 420),
    this.delay = Duration.zero,
    this.slide = true,
    this.begin = const Offset(0, 0.06),
  });

  final Widget child;
  final Duration duration;
  final Duration delay;

  /// Desplazamiento inicial, en fracciones del tamaño del hijo.
  /// `Offset(-0.6, 0)` entra de izquierda a derecha. `Offset(0, 0.06)` sube un poco.
  final Offset begin;

  /// Suma el desplazamiento de [begin]. El fundido sigue siendo el efecto principal.
  final bool slide;

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curved;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: widget.begin,
      end: Offset.zero,
    ).animate(_curved);
    _timer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;
    Widget child = FadeTransition(opacity: _curved, child: widget.child);
    if (widget.slide) {
      child = SlideTransition(position: _slide, child: child);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, faded) {
        return IgnorePointer(
          ignoring: _controller.status != AnimationStatus.completed,
          child: faded,
        );
      },
      child: child,
    );
  }
}

/// Envuelve cada widget con [FadeInWidget] y un retraso creciente.
///
/// Sirve dentro de un `ListView` o de un formulario, donde un [Column]
/// no cabe. Para una columna completa usa [StaggeredList].
///
/// [maxSteps] limita el retraso: pasado ese elemento todos aparecen juntos,
/// así un formulario largo no hace esperar a los últimos campos.
List<Widget> staggerWidgets(
  List<Widget> children, {
  int? maxSteps,
  Duration step = const Duration(milliseconds: 45),
  Duration duration = const Duration(milliseconds: 420),
  Offset begin = const Offset(0, 0.06),
}) {
  return [
    for (var index = 0; index < children.length; index++)
      FadeInWidget(
        delay: step * (maxSteps == null ? index : math.min(index, maxSteps)),
        duration: duration,
        begin: begin,
        child: children[index],
      ),
  ];
}
