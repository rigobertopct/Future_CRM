import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_motion.dart';

/// Tarjeta base: superficie con borde fino, línea de acento opcional y, si
/// tiene [onTap], respuesta táctil con brillo en el borde.
class SurfaceCard extends StatefulWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accent,
    this.onTap,
    this.selected = false,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Color de la línea vertical del borde izquierdo (por ejemplo, la etapa).
  final Color? accent;
  final VoidCallback? onTap;
  final bool selected;
  final String? semanticLabel;

  @override
  State<SurfaceCard> createState() => _SurfaceCardState();
}

class _SurfaceCardState extends State<SurfaceCard> {
  static const double _radius = 14;
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final active = _pressed || widget.selected;
    final duration = AppMotion.reduced(context)
        ? Duration.zero
        : AppMotion.fast;

    Widget content = Padding(padding: widget.padding, child: widget.child);
    if (widget.accent != null) {
      content = Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: ColoredBox(color: widget.accent!),
          ),
          Padding(
            padding: EdgeInsets.only(left: widget.accent == null ? 0 : 3),
            child: content,
          ),
        ],
      );
    }

    final card = AnimatedContainer(
      duration: duration,
      curve: AppMotion.out,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: active
              ? palette.primary.withValues(alpha: 0.55)
              : palette.border,
        ),
        boxShadow: active
            ? AppEffects.glow(palette.primary, strength: 0.5)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius - 1),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: _setPressed,
            child: content,
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      button: widget.onTap != null,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: duration,
        curve: AppMotion.out,
        child: card,
      ),
    );
  }
}
