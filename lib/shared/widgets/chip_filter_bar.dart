import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';

class FilterOption<T> {
  const FilterOption(this.value, this.label, {this.count, this.icon});

  final T value;
  final String label;
  final int? count;
  final IconData? icon;
}

/// Fila horizontal de filtros de selección única. El elegido se resalta con
/// borde y brillo; el conteo va en tipografía monoespaciada.
class ChipFilterBar<T> extends StatelessWidget {
  const ChipFilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<FilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          return _FilterChip<T>(
            option: option,
            selected: option.value == selected,
            onTap: () => onSelected(option.value),
          );
        },
      ),
    );
  }
}

class _FilterChip<T> extends StatelessWidget {
  const _FilterChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final FilterOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = selected ? palette.primary : palette.mutedForeground;
    final duration = AppMotion.reduced(context)
        ? Duration.zero
        : AppMotion.base;

    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: AnimatedContainer(
        key: ValueKey('chip-${option.label}'),
        duration: duration,
        curve: AppMotion.out,
        decoration: BoxDecoration(
          color: selected
              ? palette.primary.withValues(alpha: 0.14)
              : palette.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? palette.primary : palette.border,
          ),
          boxShadow: selected
              ? AppEffects.glow(palette.primary, strength: 0.5)
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (option.icon != null) ...[
                      Icon(option.icon, size: 15, color: color),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      option.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? palette.foreground : color,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    if (option.count != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${option.count}',
                        style: AppTypography.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
