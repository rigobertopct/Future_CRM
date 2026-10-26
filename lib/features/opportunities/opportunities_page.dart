import 'package:flutter/material.dart';

import '../../animations/animations.dart';
import '../../app/crm_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/format.dart';
import '../../shared/widgets/chip_filter_bar.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/quick_form.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/surface_card.dart';
import 'opportunities_store.dart';
import 'opportunity_details.dart';

Color opportunityColor(BuildContext context, OpportunityStage stage) {
  final palette = AppPalette.of(context);
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (stage) {
    OpportunityStage.open => palette.mutedForeground,
    OpportunityStage.qualified ||
    OpportunityStage.meeting => Tones.info(context),
    OpportunityStage.proposal => Tones.warning(context),
    OpportunityStage.negotiation =>
      dark ? const Color(0xFFB69CF0) : const Color(0xFF7A5BC7),
    OpportunityStage.won => Tones.success(context),
    OpportunityStage.lost => palette.destructive,
    OpportunityStage.cancelled => palette.mutedForeground,
  };
}

IconData opportunityIcon(OpportunityStage stage) => switch (stage) {
  OpportunityStage.open => Icons.explore_outlined,
  OpportunityStage.qualified => Icons.verified_outlined,
  OpportunityStage.meeting => Icons.event_outlined,
  OpportunityStage.proposal => Icons.description_outlined,
  OpportunityStage.negotiation => Icons.handshake_outlined,
  OpportunityStage.won => Icons.emoji_events_outlined,
  OpportunityStage.lost => Icons.cancel_outlined,
  OpportunityStage.cancelled => Icons.block,
};

class OpportunitiesPage extends StatelessWidget {
  const OpportunitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CrmScope.of(context).opportunities;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _build(context, store),
    );
  }

  Widget _build(BuildContext context, OpportunitiesStore store) {
    final items = store.visible;
    final open = store.all.where((o) => o.stage.isOpen).length;

    return PageFrame(
      title: 'Oportunidades',
      subtitle:
          '$open abiertas  ·  pipeline ${Fmt.money(store.openValue, compact: true)}'
          '  ·  ponderado ${Fmt.money(store.weightedValue, compact: true)}',
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<OpportunitySort>(
            key: const ValueKey('opportunity-sort'),
            tooltip: 'Ordenar por',
            initialValue: store.sort,
            onSelected: store.setSort,
            icon: const Icon(Icons.sort),
            itemBuilder: (context) => [
              for (final sort in OpportunitySort.values)
                PopupMenuItem(
                  value: sort,
                  child: Text('Ordenar por ${sort.label.toLowerCase()}'),
                ),
            ],
          ),
          const SizedBox(width: 4),
          ScaleOnPress(
            child: FilledButton.icon(
              key: const ValueKey('create-opportunity'),
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                minimumSize: const Size(48, 48),
              ),
              onPressed: () => _create(context, store),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva'),
            ),
          ),
        ],
      ),
      filters: ChipFilterBar<OpportunityStage?>(
        selected: store.stageFilter,
        onSelected: store.setStageFilter,
        options: [
          FilterOption(null, 'Todas', count: store.countFor(null)),
          for (final stage in OpportunityStage.values)
            FilterOption(stage, stage.label, count: store.countFor(stage)),
        ],
      ),
      child: Column(
        children: [
          if (store.loading && store.all.isNotEmpty)
            const LinearProgressIndicator(),
          if (store.error != null && store.all.isNotEmpty)
            _ErrorRow(message: store.error!, onRetry: store.refresh),
          Expanded(child: _body(context, store, items)),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    OpportunitiesStore store,
    List<Opportunity> items,
  ) {
    if (store.all.isEmpty) {
      if (store.loading) {
        return const SkeletonList(semanticLabel: 'Cargando oportunidades');
      }
      if (store.error != null) {
        return EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Sin conexión con el CRM',
          message: store.error!,
          actionLabel: 'Reintentar',
          onAction: store.refresh,
        );
      }
      return EmptyState(
        icon: Icons.trending_up,
        title: 'Aún no hay oportunidades',
        message: 'Crea la primera a partir de un contacto.',
        actionLabel: 'Nueva oportunidad',
        onAction: () => _create(context, store),
      );
    }
    return items.isEmpty
        ? EmptyState(
            icon: Icons.search_off,
            title: 'Sin resultados',
            message: 'Ninguna oportunidad coincide con los filtros.',
            actionLabel: 'Limpiar filtros',
            onAction: () {
              store.setStageFilter(null);
              CrmScope.of(context).clearSearch();
            },
          )
        : ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return FadeInWidget(
                key: ValueKey(item.id),
                delay: Duration(milliseconds: 40 * (index < 8 ? index : 8)),
                child: _OpportunityCard(item: item, store: store),
              );
            },
          );
  }

  Future<void> _create(BuildContext context, OpportunitiesStore store) async {
    final contacts = store.contacts;
    if (contacts.isEmpty) {
      showMessage(
        context,
        store.loading
            ? 'Cargando contactos, inténtalo en un momento.'
            : 'Primero crea un contacto para asociarle la oportunidad.',
      );
      return;
    }
    // Las etiquetas se repiten si dos contactos se llaman igual.
    final byLabel = <String, OpportunityContact>{};
    for (final contact in contacts) {
      var label = contact.label;
      for (var n = 2; byLabel.containsKey(label); n++) {
        label = '${contact.label} ($n)';
      }
      byLabel[label] = contact;
    }

    final values = await showQuickForm(
      context,
      title: 'Nueva oportunidad',
      submitLabel: 'Crear oportunidad',
      fields: [
        FieldSpec('contact', 'Contacto', options: byLabel.keys.toList()),
        const FieldSpec('name', 'Nombre'),
        const FieldSpec('company', 'Empresa', required: false),
        const FieldSpec(
          'amount',
          'Valor',
          keyboard: TextInputType.number,
          validator: positiveNumber,
        ),
        const FieldSpec('owner', 'Responsable', required: false),
      ],
    );
    if (values == null || !context.mounted) return;
    final contact = byLabel[values['contact']]!;
    final name = values['name']!.trim();
    final company = values['company']!.trim();
    final error = await store.add(
      OpportunityDraft(
        contactId: contact.id,
        name: name,
        company: company.isEmpty ? contact.company : company,
        amount: double.parse(values['amount']!.replaceAll(',', '.')),
        owner: values['owner']!.trim(),
      ),
    );
    if (!context.mounted) return;
    showMessage(context, error ?? 'Oportunidad "$name" creada.');
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.item, required this.store});

  final Opportunity item;
  final OpportunitiesStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = opportunityColor(context, item.stage);
    final next = item.stage.next;
    final text = Theme.of(context).textTheme;

    return SurfaceCard(
      key: ValueKey('opportunity-${item.id}'),
      accent: color,
      onTap: () => showOpportunityDetails(context, store, item.id),
      semanticLabel: 'Abrir ${item.name}',
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium,
                    ),
                    Text(
                      _subtitle(store.contactOf(item)?.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: palette.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Fmt.money(item.amount),
                style: AppTypography.mono(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.foreground,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Más acciones',
                icon: Icon(Icons.more_horiz, color: palette.mutedForeground),
                onSelected: (value) => switch (value) {
                  'delete' => _delete(context),
                  'lost' => _changeStage(context, OpportunityStage.lost),
                  'cancel' => _changeStage(context, OpportunityStage.cancelled),
                  _ => null,
                },
                itemBuilder: (context) => [
                  if (item.stage.isOpen) ...const [
                    PopupMenuItem(
                      value: 'lost',
                      child: Text('Marcar como perdida'),
                    ),
                    PopupMenuItem(value: 'cancel', child: Text('Cancelar')),
                  ],
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ProbabilityBar(value: item.chance, color: color),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PopupMenuButton<OpportunityStage>(
                tooltip: 'Cambiar etapa',
                onSelected: (stage) => _changeStage(context, stage),
                itemBuilder: (context) => [
                  for (final stage in OpportunityStage.values)
                    PopupMenuItem(value: stage, child: Text(stage.label)),
                ],
                child: StatusChip(
                  label: item.stage.label,
                  color: color,
                  icon: opportunityIcon(item.stage),
                ),
              ),
              Text(
                _meta(),
                style: AppTypography.mono(
                  fontSize: 12,
                  color: palette.mutedForeground,
                ),
              ),
              if (next != null)
                TextButton.icon(
                  key: ValueKey('advance-${item.id}'),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 40)),
                  onPressed: () => _advance(context, next),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text('Avanzar a ${next.label}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on _OpportunityCard {
  String _subtitle(String? contact) {
    final parts = [
      if (item.company.trim().isNotEmpty) item.company,
      if (contact != null && contact != item.company) contact,
    ];
    return parts.isEmpty ? 'Sin empresa' : parts.join('  ·  ');
  }

  String _meta() {
    final owner = item.owner.trim().isEmpty ? 'Sin responsable' : item.owner;
    final close = item.closeDate == null
        ? 'sin fecha de cierre'
        : Fmt.relativeDay(item.closeDate!, DateTime.now());
    return '$owner  ·  $close';
  }

  Future<void> _changeStage(
    BuildContext context,
    OpportunityStage stage,
  ) async {
    final error = await store.setStage(item.id, stage);
    if (error != null && context.mounted) showMessage(context, error);
  }

  Future<void> _advance(BuildContext context, OpportunityStage next) async {
    final previous = item.stage;
    showUndoBar(
      context,
      message: '¿Confirmas el avance de "${item.name}" a ${next.label}?',
      onUndo: () => store.setStage(item.id, previous),
    );
    final error = await store.advance(item.id);
    if (error != null && context.mounted) showMessage(context, error);
  }

  Future<void> _delete(BuildContext context) async {
    final palette = AppPalette.of(context);
    final confirmed = await Navigator.of(context).push<bool>(
      SlideUpRoute(
        builder: (context) => AlertDialog(
          title: const Text('Eliminar oportunidad'),
          content: Text('Se eliminará "${item.name}" del pipeline.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ScaleOnPress(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.destructive,
                  foregroundColor: palette.destructiveForeground,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await store.remove(item.id);
    if (!context.mounted) return;
    showMessage(context, error ?? '"${item.name}" eliminada.');
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: palette.destructive),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: palette.mutedForeground),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _ProbabilityBar extends StatelessWidget {
  const _ProbabilityBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final reduced = AppMotion.reduced(context);
    return Semantics(
      label: 'Probabilidad de cierre ${(value * 100).round()}%',
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: reduced ? value : 0, end: value),
                duration: reduced
                    ? Duration.zero
                    : const Duration(milliseconds: 700),
                curve: AppMotion.out,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 5,
                  color: color,
                  backgroundColor: palette.border,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(value * 100).round()}%',
            style: AppTypography.mono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
