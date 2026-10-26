import 'package:flutter/material.dart';

import '../../animations/animations.dart';
import '../../core/theme/app_colors.dart';

/// Estructura común de una sección: título, subtítulo, acción principal,
/// filtros y un cuerpo que ocupa el resto de la pantalla.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
    this.filters,
  });

  final String title;
  final String subtitle;
  final Widget? action;
  final Widget? filters;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final compact = MediaQuery.sizeOf(context).width < 640;
    final titles = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: palette.mutedForeground),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeInWidget(
            child: compact || action == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titles,
                      if (action != null) ...[
                        const SizedBox(height: 12),
                        action!,
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: titles),
                      action!,
                    ],
                  ),
          ),
          if (filters != null) ...[
            const SizedBox(height: 8),
            FadeInWidget(
              delay: const Duration(milliseconds: 70),
              child: filters!,
            ),
          ],
          const SizedBox(height: 4),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Estado vacío: qué pasó y, si aplica, cómo salir de él.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: palette.mutedForeground),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: palette.mutedForeground),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
