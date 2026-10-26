import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_motion.dart';

/// Sacude [child] horizontalmente cada vez que [trigger] aumenta.
///
/// Sirve para avisar de un envío rechazado (por ejemplo, un formulario con
/// errores). Con "reducir movimiento" no se mueve: el aviso debe darlo el
/// texto de error, no el movimiento.
///
/// ```dart
/// Shake(trigger: failedAttempts, child: FilledButton(...))
/// ```
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  static const _amplitude = 6.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger > oldWidget.trigger && !AppMotion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // Seno amortiguado: tres vaivenes que se apagan.
        final t = _controller.value;
        final dx = math.sin(t * math.pi * 6) * (1 - t) * _amplitude;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
