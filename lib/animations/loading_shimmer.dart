import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Bloques de carga con un brillo que recorre la superficie.
///
/// Quítalo del árbol cuando lleguen los datos. Mientras está montado la
/// animación se repite; al salir, se detiene y no bloquea la pantalla.
///
/// ```dart
/// if (loading) const LoadingShimmer() else ListView(...)
/// ```
class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({super.key, this.lines = 5});

  final int lines;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final base = palette.muted;
    final highlight = Color.lerp(palette.muted, palette.foreground, 0.14)!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (var index = 0; index < widget.lines; index++) ...[
                _ShimmerBar(
                  progress: _controller.value,
                  base: base,
                  highlight: highlight,
                  widthFactor: index.isEven ? 1 : 0.72,
                ),
                if (index != widget.lines - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({
    required this.progress,
    required this.base,
    required this.highlight,
    required this.widthFactor,
  });

  final double progress;
  final Color base;
  final Color highlight;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final slide = (progress * 2) - 1;
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1 + slide, 0),
              end: Alignment(slide, 0),
              colors: [base, highlight, base],
            ),
          ),
        ),
      ),
    );
  }
}
