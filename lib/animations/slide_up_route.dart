import 'package:flutter/material.dart';

import '../core/theme/app_motion.dart';

/// Ruta que entra desde abajo con una curva suave.
///
/// ```dart
/// final lead = await Navigator.of(context).push<Lead>(
///   SlideUpRoute(builder: (context) => LeadFormDialog()),
/// );
/// ```
class SlideUpRoute<T> extends PageRoute<T> {
  SlideUpRoute({required this.builder});

  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => const Color(0x8A000000);

  @override
  String get barrierLabel => 'Cerrar';

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 320);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.out,
      reverseCurve: AppMotion.exit,
    );
    if (AppMotion.reduced(context)) {
      return FadeTransition(opacity: curved, child: child);
    }
    // Sube desde abajo con un leve zoom; el fundido evita el corte seco.
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.6),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      ),
    );
  }
}
