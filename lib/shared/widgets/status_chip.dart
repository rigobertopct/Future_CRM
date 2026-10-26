import 'package:flutter/material.dart';

/// Etiqueta de estado: icono + texto + color. El color nunca va solo.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Colores semánticos compartidos por todas las secciones, tomados de
/// `--success`, `--info` y `--warning` de la web.
abstract final class Tones {
  static bool _dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color success(BuildContext context) =>
      _dark(context) ? const Color(0xFF68CC91) : const Color(0xFF18804B);

  static Color info(BuildContext context) =>
      _dark(context) ? const Color(0xFF82B8F5) : const Color(0xFF2874C8);

  static Color warning(BuildContext context) =>
      _dark(context) ? const Color(0xFFF0C64E) : const Color(0xFFA87400);
}
