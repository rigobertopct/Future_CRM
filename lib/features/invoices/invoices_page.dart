import 'package:flutter/material.dart';

import '../../animations/animations.dart';
import '../../app/crm_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/format.dart';
import '../../shared/widgets/animated_number.dart';
import '../../shared/widgets/chip_filter_bar.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/quick_form.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/surface_card.dart';
import 'invoices_store.dart';

Color invoiceColor(BuildContext context, InvoiceStatus status) {
  final palette = AppPalette.of(context);
  return switch (status) {
    InvoiceStatus.paid => Tones.success(context),
    InvoiceStatus.pending => Tones.info(context),
    InvoiceStatus.overdue => palette.destructive,
  };
}

IconData _icon(InvoiceStatus status) => switch (status) {
  InvoiceStatus.paid => Icons.check_circle_outline,
  InvoiceStatus.pending => Icons.schedule,
  InvoiceStatus.overdue => Icons.error_outline,
};

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CrmScope.of(context).invoices;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _build(context, store),
    );
  }

  Widget _build(BuildContext context, InvoicesStore store) {
    final items = store.visible;
    return PageFrame(
      title: 'Facturas',
      subtitle:
          '${store.all.length} emitidas  ·  ${Fmt.money(store.totalFor(InvoiceStatus.pending) + store.totalFor(InvoiceStatus.overdue), compact: true)} por cobrar',
      action: ScaleOnPress(
        child: FilledButton.icon(
          key: const ValueKey('create-invoice'),
          style: FilledButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: const Size(48, 48),
          ),
          onPressed: () => _create(context, store),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nueva factura'),
        ),
      ),
      filters: ChipFilterBar<InvoiceStatus?>(
        selected: store.statusFilter,
        onSelected: store.setStatusFilter,
        options: [
          FilterOption(null, 'Todas', count: store.countFor(null)),
          for (final s in InvoiceStatus.values)
            FilterOption(s, s.label, count: store.countFor(s)),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: items.isEmpty ? 2 : items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) return _Totals(store: store);
          if (items.isEmpty) {
            return const SizedBox(
              height: 220,
              child: EmptyState(
                icon: Icons.search_off,
                title: 'Sin resultados',
                message: 'Ninguna factura coincide con los filtros.',
              ),
            );
          }
          final invoice = items[index - 1];
          return FadeInWidget(
            key: ValueKey(invoice.id),
            delay: Duration(milliseconds: 40 * (index < 8 ? index : 8)),
            child: _InvoiceCard(invoice: invoice, store: store),
          );
        },
      ),
    );
  }

  Future<void> _create(BuildContext context, InvoicesStore store) async {
    final values = await showQuickForm(
      context,
      title: 'Nueva factura',
      submitLabel: 'Emitir factura',
      fields: const [
        FieldSpec('client', 'Cliente'),
        FieldSpec(
          'amount',
          'Importe',
          keyboard: TextInputType.number,
          validator: positiveNumber,
        ),
      ],
    );
    if (values == null || !context.mounted) return;
    final created = store.add(
      client: values['client']!,
      amount: double.parse(values['amount']!.replaceAll(',', '.')),
    );
    showMessage(context, 'Factura ${created.number} emitida.');
  }
}

/// Totales por estado. Tocar uno filtra la lista por ese estado.
class _Totals extends StatelessWidget {
  const _Totals({required this.store});

  final InvoicesStore store;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final status in InvoiceStatus.values) ...[
          Expanded(
            child: _TotalTile(
              status: status,
              amount: store.totalFor(status),
              selected: store.statusFilter == status,
              onTap: () => store.setStatusFilter(
                store.statusFilter == status ? null : status,
              ),
            ),
          ),
          if (status != InvoiceStatus.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _TotalTile extends StatelessWidget {
  const _TotalTile({
    required this.status,
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final InvoiceStatus status;
  final double amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = invoiceColor(context, status);
    return SurfaceCard(
      selected: selected,
      onTap: onTap,
      semanticLabel: '${status.label}: ${Fmt.money(amount)}',
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon(status), size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  status.label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: palette.mutedForeground),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedNumber(
              value: amount,
              format: (v) => Fmt.money(v, compact: true),
              style: AppTypography.mono(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.store});

  final Invoice invoice;
  final InvoicesStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final color = invoiceColor(context, invoice.status);
    final collectible = invoice.status != InvoiceStatus.paid;

    return SurfaceCard(
      accent: color,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
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
                      invoice.client,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium,
                    ),
                    Text(
                      '${invoice.number}  ·  emitida ${Fmt.date(invoice.issued)}',
                      style: AppTypography.mono(
                        fontSize: 12,
                        color: palette.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Fmt.money(invoice.amount),
                style: AppTypography.mono(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(
                label: invoice.status.label,
                color: color,
                icon: _icon(invoice.status),
              ),
              Text(
                invoice.status == InvoiceStatus.paid
                    ? 'Venció ${Fmt.date(invoice.due)}'
                    : 'Vence ${Fmt.relativeDay(invoice.due, DateTime.now()).toLowerCase()}',
                style: AppTypography.mono(
                  fontSize: 12,
                  color: palette.mutedForeground,
                ),
              ),
              if (invoice.reminders > 0)
                Text(
                  '${invoice.reminders} recordatorio${invoice.reminders == 1 ? '' : 's'}',
                  style: text.bodySmall?.copyWith(
                    color: palette.mutedForeground,
                  ),
                ),
            ],
          ),
          if (collectible) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  key: ValueKey('remind-${invoice.id}'),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 40)),
                  onPressed: () {
                    store.remind(invoice.id);
                    showMessage(
                      context,
                      'Recordatorio enviado a ${invoice.client}.',
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_active_outlined,
                    size: 16,
                  ),
                  label: const Text('Recordar'),
                ),
                TextButton.icon(
                  key: ValueKey('pay-${invoice.id}'),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 40)),
                  onPressed: () {
                    store.markPaid(invoice.id);
                    showMessage(
                      context,
                      'Factura ${invoice.number} marcada como pagada.',
                    );
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Marcar pagada'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
