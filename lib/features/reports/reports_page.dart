import 'package:flutter/material.dart';

import '../../animations/animations.dart';
import '../../app/crm_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/format.dart';
import '../../shared/widgets/animated_number.dart';
import '../../shared/widgets/chip_filter_bar.dart';
import '../../shared/widgets/mini_charts.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/surface_card.dart';
import '../clients/clients_store.dart';
import '../opportunities/opportunities_store.dart';

enum ReportMetric {
  revenue('Ingresos', Icons.payments_outlined, [
    138000,
    152000,
    149000,
    171000,
    166000,
    189000,
    204000,
    198000,
    221000,
    236000,
    229000,
    248000,
  ]),
  leads('Leads', Icons.people_alt_outlined, [
    88,
    94,
    91,
    103,
    99,
    115,
    122,
    118,
    131,
    140,
    136,
    152,
  ]),
  conversion('Conversión', Icons.filter_alt_outlined, [
    14.2,
    14.8,
    15.1,
    15.6,
    16.0,
    16.4,
    17.1,
    17.0,
    17.8,
    18.2,
    18.4,
    19.1,
  ]);

  const ReportMetric(this.label, this.icon, this.series);

  final String label;
  final IconData icon;

  /// Doce meses de muestra, del más antiguo al más reciente.
  final List<double> series;

  String format(double v) => switch (this) {
    revenue => Fmt.money(v, compact: true),
    leads => Fmt.integer(v),
    conversion => Fmt.percent(v),
  };

  /// Los ingresos y los leads se suman; la conversión se promedia.
  bool get additive => this != conversion;
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  ReportMetric _metric = ReportMetric.revenue;
  int _months = 6;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final crm = CrmScope.of(context);
    final now = DateTime.now();
    final values = _metric.series.sublist(12 - _months);
    final labels = [
      for (var i = _months - 1; i >= 0; i--)
        Fmt.month(DateTime(now.year, now.month - i).month),
    ];

    return PageFrame(
      title: 'Reportes',
      subtitle: 'Rendimiento comercial  ·  últimos $_months meses',
      action: SegmentedButton<int>(
        key: const ValueKey('report-range'),
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: 6, label: Text('6 meses')),
          ButtonSegment(value: 12, label: Text('12 meses')),
        ],
        selected: {_months},
        onSelectionChanged: (value) => setState(() {
          _months = value.first;
          _selected = null;
        }),
      ),
      filters: ChipFilterBar<ReportMetric>(
        selected: _metric,
        onSelected: (value) => setState(() {
          _metric = value;
          _selected = null;
        }),
        options: [
          for (final m in ReportMetric.values)
            FilterOption(m, m.label, icon: m.icon),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          FadeInWidget(
            child: _TrendCard(
              metric: _metric,
              values: values,
              labels: labels,
              selected: _selected,
              onSelect: (i) =>
                  setState(() => _selected = _selected == i ? null : i),
              color: Tones.info(context),
            ),
          ),
          const SizedBox(height: 12),
          FadeInWidget(
            delay: const Duration(milliseconds: 80),
            child: ListenableBuilder(
              listenable: crm.clients,
              builder: (context, _) => _TopClients(store: crm.clients),
            ),
          ),
          const SizedBox(height: 12),
          FadeInWidget(
            delay: const Duration(milliseconds: 160),
            child: ListenableBuilder(
              listenable: crm.opportunities,
              builder: (context, _) => _WonByOwner(store: crm.opportunities),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.metric,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onSelect,
    required this.color,
  });

  final ReportMetric metric;
  final List<double> values;
  final List<String> labels;
  final int? selected;
  final ValueChanged<int> onSelect;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final total = values.fold<double>(0, (a, b) => a + b);
    final headline = metric.additive ? total : total / values.length;
    final last = values.last;
    final previous = values[values.length - 2];
    final change = previous == 0 ? 0.0 : (last / previous - 1) * 100;
    final best = values.indexOf(values.reduce((a, b) => a > b ? a : b));

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.additive ? 'TOTAL DEL PERIODO' : 'PROMEDIO DEL PERIODO',
            style: text.labelSmall?.copyWith(
              color: palette.mutedForeground,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AnimatedNumber(
                    value: headline,
                    format: metric.format,
                    style: AppTypography.mono(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: palette.foreground,
                    ),
                  ),
                ),
              ),
              StatusChip(
                label:
                    '${change >= 0 ? '+' : ''}${Fmt.percent(change)} vs mes anterior',
                color: change >= 0
                    ? Tones.success(context)
                    : palette.destructive,
                icon: change >= 0 ? Icons.trending_up : Icons.trending_down,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Mejor mes: ${labels[best]} (${metric.format(values[best])})',
            style: text.bodySmall?.copyWith(color: palette.mutedForeground),
          ),
          const SizedBox(height: 16),
          AnimatedBarChart(
            key: ValueKey('${metric.name}-${values.length}'),
            values: values,
            labels: labels,
            color: color,
            format: metric.format,
            selected: selected,
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }
}

class _TopClients extends StatelessWidget {
  const _TopClients({required this.store});

  final ClientsStore store;

  @override
  Widget build(BuildContext context) {
    final top = ([
      ...store.all,
    ]..sort((a, b) => b.mrr.compareTo(a.mrr))).take(5).toList();
    return _RankCard(
      title: 'Top clientes por ingreso mensual',
      rows: [for (final c in top) (c.name, c.mrr)],
      format: (v) => Fmt.money(v, compact: true),
    );
  }
}

class _WonByOwner extends StatelessWidget {
  const _WonByOwner({required this.store});

  final OpportunitiesStore store;

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final o in store.all) {
      totals[o.owner] =
          (totals[o.owner] ?? 0) +
          (o.stage == OpportunityStage.won ? o.amount : 0);
    }
    final rows = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _RankCard(
      title: 'Ventas ganadas por responsable',
      rows: [for (final e in rows) (e.key, e.value)],
      format: (v) => Fmt.money(v, compact: true),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.title,
    required this.rows,
    required this.format,
  });

  final String title;
  final List<(String, double)> rows;
  final String Function(double value) format;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final reduced = AppMotion.reduced(context);
    final max = rows.isEmpty
        ? 1.0
        : rows.map((r) => r.$2).reduce((a, b) => a > b ? a : b);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        format(value),
                        style: AppTypography.mono(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: palette.foreground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: reduced ? value / max : 0,
                        end: max == 0 ? 0 : value / max,
                      ),
                      duration: reduced
                          ? Duration.zero
                          : const Duration(milliseconds: 800),
                      curve: AppMotion.out,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        color: Tones.info(context),
                        backgroundColor: palette.border,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
