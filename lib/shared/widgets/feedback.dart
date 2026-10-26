import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_motion.dart';

/// Tiempo que se ofrece deshacer antes de dar la acción por confirmada.
const undoWindow = Duration(seconds: 10);

/// Mensaje breve al pie. Reemplaza el anterior para que no se acumulen.
void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
}

/// Barra de confirmación para una acción que ya se aplicó y se puede revertir.
///
/// Una sola fila: el [message] y dos iconos, un check que confirma y una cruz
/// que deshace. Si no se toca ninguno, la acción queda confirmada al cabo de
/// [undoWindow] y la barra se cierra sola; una línea inferior muestra el
/// tiempo restante.
void showUndoBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
  VoidCallback? onConfirm,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final palette = AppPalette.of(context);
  final wide = MediaQuery.sizeOf(context).width >= 640;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        // Flutter mantiene fijo un SnackBar con acción salvo que se indique.
        persist: false,
        duration: undoWindow,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        width: wide ? 520 : null,
        margin: wide ? null : const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: _UndoBar(
          message: message,
          palette: palette,
          onConfirm: () {
            messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
            onConfirm?.call();
          },
          onUndo: () {
            messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
            onUndo();
          },
        ),
      ),
    );
}

class _UndoBar extends StatelessWidget {
  const _UndoBar({
    required this.message,
    required this.palette,
    required this.onConfirm,
    required this.onUndo,
  });

  final String message;
  final AppPalette palette;
  final VoidCallback onConfirm;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final top = Color.lerp(palette.card, palette.foreground, 0.12)!;
    final bottom = Color.lerp(palette.card, palette.background, 0.35)!;

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ),
          border: Border.all(color: palette.foreground.withValues(alpha: 0.12)),
          boxShadow: [
            // Sombra de contacto y sombra amplia: dan la sensación de elevación.
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.42),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Reflejo superior: el borde de luz que da el relieve.
              Positioned(
                left: 12,
                right: 12,
                top: 0,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 8, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: palette.foreground,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RaisedIcon(
                          key: const ValueKey('undo-bar-confirm'),
                          icon: Icons.check_rounded,
                          tooltip: 'Confirmar',
                          color: palette.primary,
                          iconColor: palette.primaryForeground,
                          filled: true,
                          onTap: onConfirm,
                        ),
                        const SizedBox(width: 4),
                        _RaisedIcon(
                          key: const ValueKey('undo-bar-undo'),
                          icon: Icons.close_rounded,
                          tooltip: 'Deshacer',
                          color: palette.destructive,
                          iconColor: palette.destructive,
                          filled: false,
                          onTap: onUndo,
                        ),
                      ],
                    ),
                  ),
                  ExcludeSemantics(
                    child: SizedBox(
                      height: 3,
                      child: reduced
                          ? null
                          : TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 1, end: 0),
                              duration: undoWindow,
                              builder: (context, remaining, _) => Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: remaining,
                                  child: ColoredBox(
                                    color: palette.primary.withValues(
                                      alpha: 0.75,
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón circular con relieve: degradado, borde de luz y halo. Mide 48 px de
/// área táctil aunque el disco visible sea de 38.
class _RaisedIcon extends StatelessWidget {
  const _RaisedIcon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.iconColor,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final Color iconColor;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: filled
                      ? [
                          Color.lerp(color, Colors.white, 0.25)!,
                          Color.lerp(color, Colors.black, 0.15)!,
                        ]
                      : [
                          color.withValues(alpha: 0.22),
                          color.withValues(alpha: 0.08),
                        ],
                ),
                border: Border.all(
                  color: filled
                      ? Colors.white.withValues(alpha: 0.35)
                      : color.withValues(alpha: 0.5),
                ),
                boxShadow: filled
                    ? AppEffects.glow(color, strength: 0.8)
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Material(
                type: MaterialType.transparency,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: SizedBox.square(
                    dimension: 38,
                    child: Icon(icon, size: 22, color: iconColor),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
