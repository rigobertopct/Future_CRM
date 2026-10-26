import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';

/// Entrega a [builder] una serie que se interpola desde la anterior cuando
/// [values] cambia. La primera vez crece desde su mínimo.
///
/// Mantén la misma longitud entre actualizaciones para que cada punto se
/// mueva hacia su nuevo valor; si cambia, se remuestrea por índice.
class AnimatedSeries extends StatefulWidget {
  const AnimatedSeries({
    super.key,
    required this.values,
    required this.builder,
    this.duration = const Duration(milliseconds: 800),
  });

  final List<double> values;
  final Widget Function(BuildContext context, List<double> values) builder;
  final Duration duration;

  @override
  State<AnimatedSeries> createState() => _AnimatedSeriesState();
}

class _AnimatedSeriesState extends State<AnimatedSeries>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late List<double> _from;
  late List<double> _to = widget.values;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final floor = widget.values.isEmpty ? 0.0 : widget.values.reduce(math.min);
    _from = List<double>.filled(widget.values.length, floor);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _from = _to;
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedSeries oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameValues(oldWidget.values, widget.values)) return;
    _from = _resample(_current(), widget.values.length);
    _to = widget.values;
    if (AppMotion.reduced(context)) {
      _from = _to;
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _sameValues(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<double> _resample(List<double> source, int length) {
    if (source.length == length || source.isEmpty) return source;
    return List<double>.generate(
      length,
      (i) => source[(i * source.length ~/ length).clamp(0, source.length - 1)],
    );
  }

  List<double> _current() {
    final t = AppMotion.out.transform(_controller.value);
    final from = _resample(_from, _to.length);
    return List<double>.generate(
      _to.length,
      (i) => from[i] + (_to[i] - from[i]) * t,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(context, _current()),
    );
  }
}

Path _smoothPath(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (var i = 1; i < points.length; i++) {
    final a = points[i - 1];
    final b = points[i];
    final mid = (a.dx + b.dx) / 2;
    path.cubicTo(mid, a.dy, mid, b.dy, b.dx, b.dy);
  }
  return path;
}

List<Offset> _project(
  List<double> values,
  Size size, {
  EdgeInsets inset = EdgeInsets.zero,
}) {
  final lo = values.reduce(math.min);
  final hi = values.reduce(math.max);
  final span = (hi - lo) == 0 ? 1.0 : hi - lo;
  final w = size.width - inset.horizontal;
  final h = size.height - inset.vertical;
  return [
    for (var i = 0; i < values.length; i++)
      Offset(
        inset.left + (values.length == 1 ? 0 : w * i / (values.length - 1)),
        inset.top + h - h * (values[i] - lo) / span,
      ),
  ];
}

/// Línea mínima con relleno degradado y un punto brillante al final.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 36,
  });

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(height: height);
    return SizedBox(
      height: height,
      child: ExcludeSemantics(
        child: AnimatedSeries(
          values: values,
          builder: (context, current) => CustomPaint(
            painter: _LinePainter(
              values: current,
              color: color,
              inset: const EdgeInsets.fromLTRB(2, 4, 6, 4),
              strokeWidth: 1.8,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.values,
    required this.color,
    required this.inset,
    required this.strokeWidth,
    this.selected,
    this.selectedLabel,
    this.gridColor,
    this.labelColor,
  });

  final List<double> values;
  final Color color;
  final EdgeInsets inset;
  final double strokeWidth;
  final int? selected;
  final String? selectedLabel;
  final Color? gridColor;
  final Color? labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    if (gridColor != null) {
      final grid = Paint()
        ..color = gridColor!
        ..strokeWidth = 1;
      for (var i = 0; i < 4; i++) {
        final y = inset.top + (size.height - inset.vertical) * i / 3;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }

    final points = _project(values, size, inset: inset);
    final line = _smoothPath(points);
    final area = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.14),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    final head = points.last;
    canvas.drawCircle(head, 6, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawCircle(head, 3, Paint()..color = color);

    final index = selected;
    if (index != null && index < points.length) {
      final p = points[index];
      canvas.drawLine(
        Offset(p.dx, 0),
        Offset(p.dx, size.height),
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(p, 5, Paint()..color = color);
      canvas.drawCircle(
        p,
        8,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = color.withValues(alpha: 0.35),
      );
      if (selectedLabel != null) _tooltip(canvas, size, p);
    }
  }

  void _tooltip(Canvas canvas, Size size, Offset anchor) {
    final text = TextPainter(
      text: TextSpan(
        text: selectedLabel,
        style: AppTypography.mono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: labelColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    const pad = 8.0;
    final w = text.width + pad * 2;
    final h = text.height + pad;
    final left = (anchor.dx - w / 2).clamp(0.0, size.width - w);
    final top = (anchor.dy - h - 12).clamp(0.0, size.height - h);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, w, h),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.2));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = color.withValues(alpha: 0.6),
    );
    text.paint(canvas, Offset(left + pad, top + pad / 2));
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values ||
      old.color != color ||
      old.selected != selected ||
      old.selectedLabel != selectedLabel;
}

/// Gráfico de área que se desplaza con los datos en vivo. Al tocar o
/// arrastrar horizontalmente muestra el valor del punto bajo el dedo.
class LiveAreaChart extends StatefulWidget {
  const LiveAreaChart({
    super.key,
    required this.values,
    required this.color,
    required this.format,
    required this.semanticLabel,
    this.height = 200,
  });

  final List<double> values;
  final Color color;
  final String Function(double value) format;
  final String semanticLabel;
  final double height;

  @override
  State<LiveAreaChart> createState() => _LiveAreaChartState();
}

class _LiveAreaChartState extends State<LiveAreaChart> {
  int? _selected;

  void _pick(double dx, double width) {
    final n = widget.values.length;
    if (n < 2) return;
    final index = (dx / width * (n - 1)).round().clamp(0, n - 1);
    if (index != _selected) setState(() => _selected = index);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      label: widget.semanticLabel,
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _pick(d.localPosition.dx, width),
              onHorizontalDragStart: (d) => _pick(d.localPosition.dx, width),
              onHorizontalDragUpdate: (d) => _pick(d.localPosition.dx, width),
              onDoubleTap: () => setState(() => _selected = null),
              child: AnimatedSeries(
                values: widget.values,
                duration: const Duration(milliseconds: 900),
                builder: (context, current) {
                  final index = _selected;
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _LinePainter(
                      values: current,
                      color: widget.color,
                      inset: const EdgeInsets.fromLTRB(4, 12, 10, 12),
                      strokeWidth: 2.4,
                      selected: index,
                      selectedLabel: index == null || index >= current.length
                          ? null
                          : widget.format(current[index]),
                      gridColor: palette.border,
                      labelColor: palette.foreground,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Barras que crecen al aparecer y cambian de altura al actualizarse.
/// Tocar una barra la resalta y muestra su valor.
class AnimatedBarChart extends StatelessWidget {
  const AnimatedBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    required this.format,
    required this.selected,
    required this.onSelect,
    this.height = 200,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final String Function(double value) format;
  final int? selected;
  final ValueChanged<int> onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final reduced = AppMotion.reduced(context);
    final top = values.isEmpty ? 1.0 : values.reduce(math.max);
    final max = top == 0 ? 1.0 : top;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: selected == i,
                label: '${labels[i]}: ${format(values[i])}',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(i),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 18,
                        child: selected == i
                            ? FittedBox(
                                child: Text(
                                  format(values[i]),
                                  style: AppTypography.mono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: reduced ? values[i] / max : 0,
                              end: values[i] / max,
                            ),
                            duration: reduced
                                ? Duration.zero
                                : Duration(milliseconds: 500 + i * 40),
                            curve: AppMotion.out,
                            builder: (context, factor, _) =>
                                FractionallySizedBox(
                                  widthFactor: 0.56,
                                  heightFactor: factor.clamp(0.02, 1.0),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6),
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          color.withValues(
                                            alpha: selected == i ? 1 : 0.7,
                                          ),
                                          color.withValues(alpha: 0.12),
                                        ],
                                      ),
                                      boxShadow: selected == i
                                          ? AppEffects.glow(
                                              color,
                                              strength: 0.7,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected == i
                              ? palette.foreground
                              : palette.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Anillo de progreso con halo; [child] queda centrado dentro.
class RingGauge extends StatelessWidget {
  const RingGauge({
    super.key,
    required this.progress,
    required this.color,
    this.size = 140,
    this.stroke = 12,
    this.child,
  });

  final double progress;
  final Color color;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final reduced = AppMotion.reduced(context);
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: reduced ? progress.clamp(0, 1) : 0,
          end: progress.clamp(0, 1),
        ),
        duration: reduced ? Duration.zero : const Duration(milliseconds: 1100),
        curve: AppMotion.out,
        builder: (context, value, _) => CustomPaint(
          painter: _RingPainter(
            progress: value,
            color: color,
            track: palette.border,
            stroke: stroke,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke);
    Paint ring(Color c, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width
      ..color = c;

    canvas.drawArc(rect, 0, math.pi * 2, false, ring(track, stroke));
    final sweep = math.pi * 2 * progress;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      ring(color.withValues(alpha: 0.2), stroke + 8),
    );
    canvas.drawArc(rect, -math.pi / 2, sweep, false, ring(color, stroke));
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
