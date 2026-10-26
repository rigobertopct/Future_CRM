import 'package:flutter/material.dart';

import 'fade_in_widget.dart';

/// Columna cuyos hijos aparecen uno tras otro.
///
/// No pongas un [Expanded] dentro: el hijo directo de la columna es el
/// fundido, y [Expanded] solo funciona como hijo directo de un [Flex].
///
/// ```dart
/// StaggeredList(
///   children: [
///     Text('Título'),
///     TextField(),
///     FilledButton(onPressed: () {}, child: Text('Entrar')),
///   ],
/// )
/// ```
class StaggeredList extends StatelessWidget {
  const StaggeredList({
    super.key,
    required this.children,
    this.step = const Duration(milliseconds: 55),
    this.duration = const Duration(milliseconds: 420),
    this.begin = const Offset(0, 0.06),
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.max,
  });

  final List<Widget> children;
  final Duration step;
  final Duration duration;
  final Offset begin;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: staggerWidgets(
        children,
        step: step,
        duration: duration,
        begin: begin,
      ),
    );
  }
}
