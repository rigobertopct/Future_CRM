import 'package:flutter/material.dart';

import '../../animations/animations.dart';
import '../../app/crm_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/format.dart';
import '../../shared/widgets/animated_number.dart';
import '../../shared/widgets/chip_filter_bar.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/mini_charts.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/quick_form.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/surface_card.dart';
import 'clients_store.dart';

Color _statusColor(BuildContext context, ClientStatus status) {
  final palette = AppPalette.of(context);
  return switch (status) {
    ClientStatus.active => Tones.success(context),
    ClientStatus.atRisk => Tones.warning(context),
    ClientStatus.inactive => palette.mutedForeground,
  };
}

IconData _statusIcon(ClientStatus status) => switch (status) {
  ClientStatus.active => Icons.check_circle_outline,
  ClientStatus.atRisk => Icons.warning_amber_rounded,
  ClientStatus.inactive => Icons.pause_circle_outline,
};

Color _healthColor(BuildContext context, int health) {
  final palette = AppPalette.of(context);
  if (health >= 75) return Tones.success(context);
  if (health >= 50) return Tones.warning(context);
  return palette.destructive;
}

class ClientsPage extends StatelessWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CrmScope.of(context).clients;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _build(context, store),
    );
  }

  Widget _build(BuildContext context, ClientsStore store) {
    final items = store.visible;
    return PageFrame(
      title: 'Clientes',
      subtitle:
          '${store.all.length} cuentas  ·  ${Fmt.money(store.totalMrr, compact: true)} al mes'
          '  ·  ${store.atRiskCount} en riesgo',
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<ClientSort>(
            key: const ValueKey('client-sort'),
            tooltip: 'Ordenar por',
            initialValue: store.sort,
            onSelected: store.setSort,
            icon: const Icon(Icons.sort),
            itemBuilder: (context) => [
              for (final sort in ClientSort.values)
                PopupMenuItem(
                  value: sort,
                  child: Text('Ordenar por ${sort.label.toLowerCase()}'),
                ),
            ],
          ),
          const SizedBox(width: 4),
          ScaleOnPress(
            child: FilledButton.icon(
              key: const ValueKey('create-client'),
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                minimumSize: const Size(48, 48),
              ),
              onPressed: () => _create(context, store),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo'),
            ),
          ),
        ],
      ),
      filters: ChipFilterBar<ClientFilter>(
        selected: store.filter,
        onSelected: store.setFilter,
        options: [
          FilterOption(
            const AllClients(),
            'Todos',
            count: store.countFor(const AllClients()),
          ),
          for (final segment in ClientSegment.values)
            FilterOption(
              SegmentClients(segment),
              segment.label,
              count: store.countFor(SegmentClients(segment)),
            ),
          FilterOption(
            const FavoriteClients(),
            'Favoritos',
            icon: Icons.star_outline,
            count: store.countFor(const FavoriteClients()),
          ),
        ],
      ),
      child: items.isEmpty
          ? EmptyState(
              icon: Icons.search_off,
              title: 'Sin resultados',
              message: 'Ningún cliente coincide con los filtros.',
              actionLabel: 'Limpiar filtros',
              onAction: () {
                store.setFilter(const AllClients());
                CrmScope.of(context).clearSearch();
              },
            )
          : ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final client = items[index];
                return FadeInWidget(
                  key: ValueKey(client.id),
                  delay: Duration(milliseconds: 40 * (index < 8 ? index : 8)),
                  child: _ClientCard(client: client, store: store),
                );
              },
            ),
    );
  }

  Future<void> _create(BuildContext context, ClientsStore store) async {
    final values = await showQuickForm(
      context,
      title: 'Nuevo cliente',
      submitLabel: 'Crear cliente',
      fields: [
        const FieldSpec('name', 'Nombre de la empresa'),
        const FieldSpec('industry', 'Sector'),
        FieldSpec(
          'segment',
          'Segmento',
          options: [for (final s in ClientSegment.values) s.label],
        ),
        const FieldSpec('contact', 'Contacto principal'),
        FieldSpec(
          'email',
          'Correo',
          keyboard: TextInputType.emailAddress,
          validator: (v) =>
              v.contains('@') ? null : 'Escribe un correo válido.',
        ),
        const FieldSpec(
          'mrr',
          'Ingreso mensual',
          keyboard: TextInputType.number,
          validator: positiveNumber,
        ),
      ],
    );
    if (values == null || !context.mounted) return;
    store.add(
      name: values['name']!,
      industry: values['industry']!,
      segment: ClientSegment.values.firstWhere(
        (s) => s.label == values['segment'],
      ),
      contact: values['contact']!,
      email: values['email']!,
      mrr: double.parse(values['mrr']!.replaceAll(',', '.')),
    );
    showMessage(context, 'Cliente "${values['name']}" creado.');
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client, required this.store});

  final Client client;
  final ClientsStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final statusColor = _statusColor(context, client.status);

    return SurfaceCard(
      onTap: () => _showDetails(context, store, client.id),
      semanticLabel:
          '${client.name}, ${client.status.label}, salud ${client.health} de 100',
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          RingGauge(
            progress: client.health / 100,
            color: _healthColor(context, client.health),
            size: 48,
            stroke: 3.5,
            child: Text(
              client.initials,
              style: AppTypography.mono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.foreground,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium,
                ),
                Text(
                  '${client.industry}  ·  ${client.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: palette.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusChip(
                      label: client.status.label,
                      color: statusColor,
                      icon: _statusIcon(client.status),
                    ),
                    Text(
                      '${Fmt.money(client.mrr)}/mes',
                      style: AppTypography.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.foreground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('favorite-${client.id}'),
            tooltip: client.favorite
                ? 'Quitar de favoritos'
                : 'Marcar como favorito',
            onPressed: () => store.toggleFavorite(client.id),
            icon: Icon(
              client.favorite ? Icons.star : Icons.star_outline,
              color: client.favorite
                  ? Tones.warning(context)
                  : palette.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showDetails(BuildContext context, ClientsStore store, String id) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    sheetAnimationStyle: AppMotion.sheet(context),
    backgroundColor: AppPalette.of(context).card,
    builder: (context) => ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final client = store.all.where((c) => c.id == id).firstOrNull;
        if (client == null) return const SizedBox.shrink();
        return _ClientDetails(client: client, store: store);
      },
    ),
  );
}

class _ClientDetails extends StatelessWidget {
  const _ClientDetails({required this.client, required this.store});

  final Client client;
  final ClientsStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final color = _healthColor(context, client.health);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.name, style: text.headlineSmall),
                    Text(
                      '${client.industry}  ·  ${client.segment.label}  ·  ${client.city}',
                      style: text.bodySmall?.copyWith(
                        color: palette.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: client.favorite
                    ? 'Quitar de favoritos'
                    : 'Marcar como favorito',
                onPressed: () => store.toggleFavorite(client.id),
                icon: Icon(
                  client.favorite ? Icons.star : Icons.star_outline,
                  color: client.favorite ? Tones.warning(context) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: RingGauge(
              progress: client.health / 100,
              color: color,
              size: 132,
              stroke: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedNumber(
                    value: client.health.toDouble(),
                    format: (v) => v.round().toString(),
                    style: AppTypography.mono(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: palette.foreground,
                    ),
                  ),
                  Text(
                    'SALUD',
                    style: text.labelSmall?.copyWith(
                      color: palette.mutedForeground,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _Row(
            label: 'Ingreso mensual',
            value: Fmt.money(client.mrr),
            mono: true,
          ),
          _Row(label: 'Contacto', value: client.contact),
          _Row(label: 'Correo', value: client.email, mono: true),
          const SizedBox(height: 16),
          Text(
            'ESTADO DE LA CUENTA',
            style: text.labelSmall?.copyWith(
              color: palette.mutedForeground,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in ClientStatus.values)
                ChoiceChip(
                  key: ValueKey('status-${status.name}'),
                  avatar: Icon(_statusIcon(status), size: 16),
                  label: Text(status.label),
                  selected: client.status == status,
                  onSelected: (_) {
                    store.setStatus(client.id, status);
                    showMessage(
                      context,
                      '${client.name} ahora está ${status.label.toLowerCase()}.',
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: palette.mutedForeground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: mono
                  ? AppTypography.mono(fontSize: 13, color: palette.foreground)
                  : Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
