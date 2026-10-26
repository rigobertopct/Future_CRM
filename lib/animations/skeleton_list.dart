import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';

/// Esqueleto de una lista: filas con avatar, dos líneas de texto y una
/// etiqueta, con un brillo que las recorre mientras llegan los datos.
///
/// Con "reducir movimiento" el brillo no se anima y las filas quedan quietas.
///
/// ```dart
/// if (loading) const SkeletonList(semanticLabel: 'Cargando leads')
/// ```
class SkeletonList extends StatefulWidget {
  const SkeletonList({
    super.key,
    this.rows = 6,
    this.semanticLabel = 'Cargando',
  });

  final int rows;
  final String semanticLabel;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
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
    final highlight = Color.lerp(palette.muted, palette.foreground, 0.12)!;

    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              // Un único degradado desplazado: todas las piezas brillan a la vez.
              final slide = _controller.value * 3 - 1;
              final gradient = LinearGradient(
                begin: Alignment(-1 + slide, -0.3),
                end: Alignment(slide, 0.3),
                colors: [base, highlight, base],
              );
              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: widget.rows,
                separatorBuilder: (_, _) => const SizedBox(height: 18),
                itemBuilder: (context, index) =>
                    _SkeletonRow(gradient: gradient, wide: index.isEven),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.gradient, required this.wide});

  final Gradient gradient;
  final bool wide;

  Widget _block(double? width, double height, {double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _block(40, 40, radius: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FractionallySizedBox(
                widthFactor: wide ? 0.62 : 0.48,
                child: _block(null, 14),
              ),
              const SizedBox(height: 8),
              FractionallySizedBox(
                widthFactor: wide ? 0.4 : 0.34,
                child: _block(null, 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _block(64, 24, radius: 12),
      ],
    );
  }
}
