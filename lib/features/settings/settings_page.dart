import 'package:flutter/material.dart';

import '../../animations/animations.dart';
import '../../app/crm_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/surface_card.dart';
import 'settings_store.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final crm = CrmScope.of(context);
    final store = crm.settings;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => PageFrame(
        title: 'Configuración',
        subtitle: 'Preferencias de esta sesión',
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          children: staggerWidgets([
            _Profile(crm: crm),
            _Section(
              title: 'Apariencia',
              children: [
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: crm.themeMode,
                  builder: (context, mode, _) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 8,
                      spacing: 12,
                      children: [
                        const Text('Tema'),
                        SegmentedButton<ThemeMode>(
                          key: const ValueKey('theme-mode'),
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_outlined, size: 18),
                              label: Text('Oscuro'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_outlined, size: 18),
                              label: Text('Claro'),
                            ),
                          ],
                          selected: {mode},
                          onSelectionChanged: (_) => crm.toggleTheme(),
                        ),
                      ],
                    ),
                  ),
                ),
                _Toggle(
                  key: const ValueKey('reduce-motion'),
                  title: 'Reducir movimiento',
                  subtitle: 'Desactiva transiciones y animaciones decorativas.',
                  value: store.reduceMotion,
                  onChanged: store.setReduceMotion,
                ),
              ],
            ),
            _Section(
              title: 'Datos en vivo',
              children: [
                _Toggle(
                  key: const ValueKey('live-updates'),
                  title: 'Actualizar el dashboard en tiempo real',
                  subtitle: 'Se pausa solo al salir del dashboard o de la app.',
                  value: store.liveUpdates,
                  onChanged: store.setLiveUpdates,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Velocidad'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final speed in LiveSpeed.values)
                            ChoiceChip(
                              key: ValueKey('speed-${speed.name}'),
                              label: Text('${speed.label} · ${speed.seconds}s'),
                              selected: store.speed == speed,
                              onSelected: store.liveUpdates
                                  ? (_) => store.setSpeed(speed)
                                  : null,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _Section(
              title: 'Notificaciones',
              children: [
                _Toggle(
                  title: 'Oportunidades',
                  subtitle: 'Cambios de etapa y nuevas oportunidades.',
                  value: store.notifyDeals,
                  onChanged: store.setNotifyDeals,
                ),
                _Toggle(
                  title: 'Tareas',
                  subtitle: 'Vencimientos y asignaciones.',
                  value: store.notifyTasks,
                  onChanged: store.setNotifyTasks,
                ),
                _Toggle(
                  title: 'Facturas',
                  subtitle: 'Pagos recibidos y facturas vencidas.',
                  value: store.notifyInvoices,
                  onChanged: store.setNotifyInvoices,
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

/// Resumen de la sesión; los datos se editan en Cuenta.
class _Profile extends StatelessWidget {
  const _Profile({required this.crm});

  final CrmController crm;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final profile = crm.session.profile;
    if (profile == null) return const SizedBox.shrink();
    return SurfaceCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: palette.primary.withValues(alpha: 0.16),
            child: Text(
              profile.initials,
              style: AppTypography.mono(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: palette.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.fullName, style: text.titleMedium),
                Text(
                  profile.email,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: palette.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            key: const ValueKey('open-account'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => crm.open(CrmSection.account),
            child: const Text('Gestionar'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: palette.mutedForeground, letterSpacing: 0.8),
          ),
        ),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
