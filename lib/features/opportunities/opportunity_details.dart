import 'package:flutter/material.dart';

import '../../animations/animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/format.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/quick_form.dart';
import '../../shared/widgets/status_chip.dart';
import 'opportunities_page.dart';
import 'opportunities_store.dart';

/// Hoja con el detalle de la oportunidad, su edición y el historial de
/// etapas (`pipelines`). Se cierra sola si la oportunidad desaparece.
Future<void> showOpportunityDetails(
  BuildContext context,
  OpportunitiesStore store,
  String id,
) {
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
        final item = store.all.where((o) => o.id == id).firstOrNull;
        if (item == null) return const SizedBox.shrink();
        return _Details(item: item, store: store);
      },
    ),
  );
}

class _Details extends StatelessWidget {
  const _Details({required this.item, required this.store});

  final Opportunity item;
  final OpportunitiesStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final color = opportunityColor(context, item.stage);
    final contact = store.contactOf(item);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(item.name, style: text.headlineSmall),
          if (item.company.trim().isNotEmpty)
            Text(
              item.company,
              style: text.bodySmall?.copyWith(color: palette.mutedForeground),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip(
              label: item.stage.label,
              color: color,
              icon: opportunityIcon(item.stage),
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Valor', value: Fmt.money(item.amount), mono: true),
          _InfoRow(
            label: 'Probabilidad',
            value: item.probability == null
                ? '${(item.chance * 100).round()}% (según la etapa)'
                : '${(item.chance * 100).round()}%',
            mono: true,
          ),
          _InfoRow(
            label: 'Ponderado',
            value: Fmt.money(item.weighted),
            mono: true,
          ),
          _InfoRow(label: 'Contacto', value: contact?.name ?? '—'),
          _InfoRow(label: 'Responsable', value: _orDash(item.owner)),
          _InfoRow(
            label: 'Cierre',
            value: item.closeDate == null
                ? 'Sin fecha'
                : '${Fmt.date(item.closeDate!)} ${item.closeDate!.year}',
          ),
          _InfoRow(label: 'Tipo de pago', value: item.paymentType.label),
          if (item.description.trim().isNotEmpty)
            _TextBlock(label: 'Descripción', value: item.description),
          if (item.note.trim().isNotEmpty)
            _TextBlock(label: 'Nota', value: item.note),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ScaleOnPress(
                  child: FilledButton.icon(
                    key: const ValueKey('edit-opportunity'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => _edit(context),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('change-stage'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () => _changeStage(context),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Cambiar etapa'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'HISTORIAL DE ETAPAS',
            style: text.labelSmall?.copyWith(
              color: palette.mutedForeground,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          // Una etapa nueva vuelve a pedir el historial.
          _History(
            key: ValueKey('${item.id}-${item.stage.raw}'),
            item: item,
            store: store,
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final payments = {for (final p in PaymentType.values) p.label: p};
    final chance = item.probability;
    final values = await showQuickForm(
      context,
      title: 'Editar oportunidad',
      submitLabel: 'Guardar cambios',
      fields: [
        FieldSpec('name', 'Nombre', initial: item.name),
        FieldSpec('company', 'Empresa', required: false, initial: item.company),
        FieldSpec(
          'amount',
          'Valor',
          keyboard: TextInputType.number,
          validator: positiveNumber,
          initial: _plain(item.amount),
        ),
        FieldSpec(
          'probability',
          'Probabilidad (%)',
          keyboard: TextInputType.number,
          required: false,
          validator: percentValue,
          initial: chance == null ? '' : (chance * 100).round().toString(),
        ),
        FieldSpec('owner', 'Responsable', required: false, initial: item.owner),
        FieldSpec(
          'close',
          'Fecha de cierre',
          // La API no permite quitar una fecha ya guardada.
          required: item.closeDate != null,
          date: true,
          initial: item.closeDate == null ? '' : apiDate(item.closeDate!),
        ),
        FieldSpec(
          'payment',
          'Tipo de pago',
          options: payments.keys.toList(),
          initial: item.paymentType.label,
        ),
        FieldSpec(
          'description',
          'Descripción',
          required: false,
          maxLines: 4,
          initial: item.description,
        ),
        FieldSpec(
          'note',
          'Nota',
          required: false,
          maxLines: 3,
          initial: item.note,
        ),
      ],
    );
    if (values == null || !context.mounted) return;

    final probability = values['probability']!;
    final close = values['close']!;
    final error = await store.edit(
      item.copyWith(
        name: values['name'],
        company: values['company'],
        amount: double.parse(values['amount']!.replaceAll(',', '.')),
        probability: () =>
            probability.isEmpty ? null : int.parse(probability) / 100,
        owner: values['owner'],
        closeDate: () => close.isEmpty ? null : DateTime.parse(close),
        paymentType: payments[values['payment']],
        description: values['description'],
        note: values['note'],
      ),
    );
    if (!context.mounted) return;
    showMessage(context, error ?? 'Cambios guardados.');
  }

  Future<void> _changeStage(BuildContext context) async {
    final stages = {
      for (final s in OpportunityStage.values)
        if (s != item.stage) s.label: s,
    };
    final values = await showQuickForm(
      context,
      title: 'Cambiar etapa',
      submitLabel: 'Guardar etapa',
      fields: [
        FieldSpec(
          'stage',
          'Nueva etapa',
          options: stages.keys.toList(),
          initial: item.stage.next?.label ?? '',
        ),
        const FieldSpec(
          'note',
          'Nota para el historial',
          required: false,
          maxLines: 3,
        ),
      ],
    );
    if (values == null || !context.mounted) return;
    final error = await store.setStage(
      item.id,
      stages[values['stage']]!,
      note: values['note']!,
    );
    if (error != null && context.mounted) showMessage(context, error);
  }
}

class _History extends StatefulWidget {
  const _History({super.key, required this.item, required this.store});

  final Opportunity item;
  final OpportunitiesStore store;

  @override
  State<_History> createState() => _HistoryState();
}

class _HistoryState extends State<_History> {
  late Future<List<PipelineEntry>> _future = _load();

  Future<List<PipelineEntry>> _load() => widget.store.history(widget.item.id);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: palette.mutedForeground);
    return FutureBuilder<List<PipelineEntry>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(
              semanticsLabel: 'Cargando historial',
            ),
          );
        }
        if (snapshot.hasError) {
          return Row(
            children: [
              Expanded(
                child: Text(
                  'No se pudo cargar el historial: ${snapshot.error}',
                  style: muted,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _future = _load()),
                child: const Text('Reintentar'),
              ),
            ],
          );
        }
        final entries = snapshot.data!;
        if (entries.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin cambios de etapa todavía. Cada cambio queda registrado aquí.',
              style: muted,
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < entries.length; i++)
              _HistoryTile(entry: entries[i], last: i == entries.length - 1),
          ],
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry, required this.last});

  final PipelineEntry entry;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final color = opportunityColor(context, entry.stage);
    final at = entry.at;
    final when = at == null
        ? 'Fecha desconocida'
        : '${Fmt.date(at)} ${at.year}  ·  '
              '${at.hour.toString().padLeft(2, '0')}:'
              '${at.minute.toString().padLeft(2, '0')}';

    return MergeSemantics(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Icon(opportunityIcon(entry.stage), size: 18, color: color),
                  if (!last)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: palette.border,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.stage.label, style: text.titleSmall),
                    Text(
                      when,
                      style: AppTypography.mono(
                        fontSize: 11,
                        color: palette.mutedForeground,
                      ),
                    ),
                    if (entry.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(entry.note, style: text.bodySmall),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: text.bodySmall?.copyWith(color: palette.mutedForeground),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: mono
                    ? AppTypography.mono(
                        fontSize: 13,
                        color: palette.foreground,
                      )
                    : text.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.bodySmall?.copyWith(color: palette.mutedForeground),
          ),
          const SizedBox(height: 2),
          Text(value, style: text.bodyMedium),
        ],
      ),
    );
  }
}

String _orDash(String value) => value.trim().isEmpty ? '—' : value;

String _plain(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();
