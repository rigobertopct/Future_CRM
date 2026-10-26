import 'package:flutter/material.dart';

import '../../animations/animations.dart';
import '../../app/crm_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/format.dart';
import '../../shared/widgets/animated_number.dart';
import '../../shared/widgets/chip_filter_bar.dart';
import '../../shared/widgets/mini_charts.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/surface_card.dart';
import '../invoices/invoices_store.dart';
import '../opportunities/opportunities_page.dart';
import '../opportunities/opportunities_store.dart';
import 'dashboard_store.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  DashboardStore? _store;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_store != null) return;
    _store = CrmScope.of(context).dashboard..attach();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _store?.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store?.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crm = CrmScope.of(context);
    final store = crm.dashboard;
    return ListenableBuilder(
      listenable: Listenable.merge([
        store,
        crm.opportunities,
        crm.tasks,
        crm.invoices,
        crm.clients,
      ]),
      builder: (context, _) => PageFrame(
        title: 'Dashboard',
        subtitle: 'Pulso comercial en tiempo real',
        action: _LiveControls(crm: crm),
        filters: ChipFilterBar<DashboardPeriod>(
          selected: store.period,
          onSelected: store.setPeriod,
          options: [
            for (final p in DashboardPeriod.values) FilterOption(p, p.label),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) =>
              _Content(crm: crm, width: constraints.maxWidth),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.crm, required this.width});

  final CrmController crm;
  final double width;

  @override
  Widget build(BuildContext context) {
    final store = crm.dashboard;
    final wide = width >= 860;
    const gap = 12.0;

    final pipeline = crm.opportunities.openValue + store.pipelineDrift;
    final period = store.period;
    final revenueGrowth =
        12.4 + (store.revenue - period.revenue) / period.revenue * 100;
    final leadGrowth = 8.1 + (store.leads - period.leads) / period.leads * 100;
    final dealColor = opportunityColor(context, OpportunityStage.negotiation);

    final kpis = [
      _Kpi(
        icon: Icons.people_alt_outlined,
        label: 'Leads nuevos',
        value: store.leads.toDouble(),
        format: Fmt.integer,
        delta: leadGrowth,
        spark: store.leadsSpark,
        color: Tones.info(context),
        flashKey: store.leads,
        onTap: () => crm.open(CrmSection.leads),
      ),
      _Kpi(
        icon: Icons.filter_alt_outlined,
        label: 'Conversión',
        value: store.conversion,
        format: Fmt.percent,
        delta: 1.3,
        deltaSuffix: ' pts',
        spark: store.conversionSpark,
        color: Tones.warning(context),
        flashKey: (store.conversion * 10).round(),
        onTap: () => crm.open(CrmSection.reports),
      ),
      _Kpi(
        icon: Icons.account_tree_outlined,
        label: 'Pipeline abierto',
        value: pipeline,
        format: (v) => Fmt.money(v, compact: true),
        delta: 5.7,
        spark: store.pipelineSpark,
        color: dealColor,
        flashKey: pipeline.round(),
        onTap: () => crm.open(CrmSection.opportunities),
      ),
    ];

    final overdue = crm.invoices.totalFor(InvoiceStatus.overdue);
    final pulse = [
      _Pulse(
        icon: Icons.task_alt,
        label: 'Tareas pendientes',
        value: crm.tasks.pendingCount.toDouble(),
        format: Fmt.integer,
        onTap: () => crm.open(CrmSection.tasks),
      ),
      _Pulse(
        icon: Icons.error_outline,
        label: 'Facturas vencidas',
        value: overdue,
        format: (v) => Fmt.money(v, compact: true),
        onTap: () {
          crm.invoices.setStatusFilter(InvoiceStatus.overdue);
          crm.open(CrmSection.invoices);
        },
      ),
      _Pulse(
        icon: Icons.warning_amber_rounded,
        label: 'Clientes en riesgo',
        value: crm.clients.atRiskCount.toDouble(),
        format: Fmt.integer,
        onTap: () => crm.open(CrmSection.clients),
      ),
    ];

    final funnel = _Funnel(crm: crm);
    final goal = _Goal(store: store);

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        FadeInWidget(
          child: _Hero(crm: crm, growth: revenueGrowth),
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Indicadores'),
        if (wide)
          Row(
            children: [
              for (var i = 0; i < kpis.length; i++) ...[
                Expanded(
                  child: FadeInWidget(
                    delay: Duration(milliseconds: 60 * (i + 1)),
                    child: kpis[i],
                  ),
                ),
                if (i < kpis.length - 1) const SizedBox(width: gap),
              ],
            ],
          )
        else
          // Tarjetas en fila deslizable: la siguiente asoma para invitar al gesto.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < kpis.length; i++) ...[
                  SizedBox(
                    width: 164,
                    child: FadeInWidget(
                      delay: Duration(milliseconds: 60 * (i + 1)),
                      child: kpis[i],
                    ),
                  ),
                  if (i < kpis.length - 1) const SizedBox(width: gap),
                ],
              ],
            ),
          ),
        const SizedBox(height: 20),
        const _SectionTitle('Requiere atención'),
        FadeInWidget(
          delay: const Duration(milliseconds: 240),
          child: Row(
            children: [
              for (var i = 0; i < pulse.length; i++) ...[
                Expanded(child: pulse[i]),
                if (i < pulse.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: gap),
        FadeInWidget(
          delay: const Duration(milliseconds: 300),
          child: _RevenueChart(store: store),
        ),
        const SizedBox(height: gap),
        FadeInWidget(
          delay: const Duration(milliseconds: 360),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: funnel),
                    const SizedBox(width: gap),
                    Expanded(flex: 2, child: goal),
                  ],
                )
              : Column(
                  children: [
                    funnel,
                    const SizedBox(height: gap),
                    goal,
                  ],
                ),
        ),
        const SizedBox(height: gap),
        FadeInWidget(
          delay: const Duration(milliseconds: 420),
          child: _Feed(store: store),
        ),
      ],
    );
  }
}

// ─── Controles en vivo ───────────────────────────────────────────────────

class _LiveControls extends StatelessWidget {
  const _LiveControls({required this.crm});

  final CrmController crm;

  @override
  Widget build(BuildContext context) {
    final store = crm.dashboard;
    final palette = AppPalette.of(context);
    final live = store.live;
    final color = live ? Tones.success(context) : palette.mutedForeground;
    final reduced = AppMotion.reduced(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: false,
          label: live ? 'Datos en vivo' : 'Datos en pausa',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // El punto pulsa una vez por actualización, no en bucle.
                TweenAnimationBuilder<double>(
                  key: ValueKey(store.ticks),
                  tween: Tween<double>(begin: live && !reduced ? 1 : 0, end: 0),
                  duration: const Duration(milliseconds: 900),
                  curve: AppMotion.out,
                  builder: (context, pulse, _) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6 * pulse),
                          blurRadius: 10 * pulse,
                          spreadRadius: 4 * pulse,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  live ? 'EN VIVO' : 'PAUSADO',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('live-toggle'),
          tooltip: live ? 'Pausar datos en vivo' : 'Reanudar datos en vivo',
          onPressed: () =>
              crm.settings.setLiveUpdates(!crm.settings.liveUpdates),
          icon: Icon(
            live ? Icons.pause_circle_outline : Icons.play_circle_outline,
          ),
        ),
      ],
    );
  }
}

// ─── Cabecera ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

/// Cabecera a todo el ancho en el color primario: la cifra del periodo en
/// grande, el avance hacia la meta y accesos rápidos a las secciones clave.
class _Hero extends StatelessWidget {
  const _Hero({required this.crm, required this.growth});

  final CrmController crm;
  final double growth;

  @override
  Widget build(BuildContext context) {
    final store = crm.dashboard;
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final on = palette.primaryForeground;
    final up = growth >= 0;
    final reached = store.goalProgress >= 1;
    final reduced = AppMotion.reduced(context);

    const actions = [
      (CrmSection.leads, 'Leads', Icons.person_add_alt_1_outlined),
      (CrmSection.opportunities, 'Pipeline', Icons.trending_up),
      (CrmSection.tasks, 'Tareas', Icons.task_alt),
      (CrmSection.invoices, 'Facturas', Icons.receipt_long_outlined),
    ];

    return Container(
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppEffects.glow(palette.primary, strength: 0.6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Brillo suave en la esquina, sin añadir colores a la paleta.
            Positioned(
              top: -70,
              right: -50,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ingresos · ${store.period.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelLarge?.copyWith(
                            color: on.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: on.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              up ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 12,
                              color: on,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              Fmt.percent(growth.abs()),
                              style: AppTypography.mono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: on,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Semantics(
                    label: 'Ingresos del periodo: ${Fmt.money(store.revenue)}',
                    excludeSemantics: true,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AnimatedNumber(
                        value: store.revenue,
                        format: Fmt.money,
                        style: AppTypography.mono(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: on,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: reduced ? store.goalProgress : 0,
                              end: store.goalProgress,
                            ),
                            duration: reduced
                                ? Duration.zero
                                : const Duration(milliseconds: 800),
                            curve: AppMotion.out,
                            builder: (context, v, _) => LinearProgressIndicator(
                              value: v.clamp(0, 1),
                              minHeight: 6,
                              color: on,
                              backgroundColor: on.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        reached
                            ? 'Meta superada'
                            : '${(store.goalProgress * 100).round()}% de '
                                  '${Fmt.money(store.period.goal, compact: true)}',
                        style: text.labelMedium?.copyWith(color: on),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final (section, label, icon) in actions)
                        _HeroAction(
                          key: ValueKey('hero-${section.name}'),
                          icon: icon,
                          label: label,
                          onTap: () => crm.open(section),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final on = AppPalette.of(context).primaryForeground;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on.withValues(alpha: 0.16),
                    border: Border.all(color: on.withValues(alpha: 0.28)),
                  ),
                  child: Icon(icon, size: 22, color: on),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: on),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── KPI ─────────────────────────────────────────────────────────────────

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.format,
    required this.delta,
    required this.spark,
    required this.color,
    required this.flashKey,
    required this.onTap,
    this.deltaSuffix = '%',
  });

  final IconData icon;
  final String label;
  final double value;
  final String Function(double) format;
  final double delta;
  final String deltaSuffix;
  final List<double> spark;
  final Color color;
  final int flashKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final up = delta >= 0;

    return _FlashGlow(
      flashKey: flashKey,
      color: color,
      child: SurfaceCard(
        onTap: onTap,
        semanticLabel: '$label: ${format(value)}',
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: palette.mutedForeground),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedNumber(
                value: value,
                format: format,
                style: AppTypography.mono(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: palette.foreground,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  up ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: up ? Tones.success(context) : palette.destructive,
                ),
                const SizedBox(width: 2),
                Text(
                  '${Fmt.percent(delta.abs()).replaceAll('%', '')}$deltaSuffix',
                  style: AppTypography.mono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: up ? Tones.success(context) : palette.destructive,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            RepaintBoundary(
              child: Sparkline(values: spark, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Halo que destella cuando [flashKey] cambia y se apaga solo. Mantiene el
/// estado del hijo, así los gráficos de dentro no reinician su animación.
class _FlashGlow extends StatefulWidget {
  const _FlashGlow({
    required this.flashKey,
    required this.color,
    required this.child,
  });

  final int flashKey;
  final Color color;
  final Widget child;

  @override
  State<_FlashGlow> createState() => _FlashGlowState();
}

class _FlashGlowState extends State<_FlashGlow>
    with SingleTickerProviderStateMixin {
  // Arranca en 1 (apagado): solo destella ante un cambio, no al aparecer.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    value: 1,
  );

  @override
  void didUpdateWidget(_FlashGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flashKey != widget.flashKey && !AppMotion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final flash = 1 - AppMotion.out.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: flash <= 0.01
                ? null
                : AppEffects.glow(widget.color, strength: flash * 0.9),
          ),
          child: child,
        );
      },
    );
  }
}

class _Pulse extends StatelessWidget {
  const _Pulse({
    required this.icon,
    required this.label,
    required this.value,
    required this.format,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final double value;
  final String Function(double) format;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SurfaceCard(
      onTap: onTap,
      semanticLabel: '$label: ${format(value)}',
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: palette.mutedForeground),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedNumber(
              value: value,
              format: format,
              style: AppTypography.mono(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: palette.foreground,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: palette.mutedForeground),
          ),
        ],
      ),
    );
  }
}

// ─── Gráfico principal ───────────────────────────────────────────────────

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.store});

  final DashboardStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final series = store.series;
    final last = series.last;
    final max = series.reduce((a, b) => a > b ? a : b);
    final min = series.reduce((a, b) => a < b ? a : b);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ingresos en tiempo real', style: text.titleMedium),
                    Text(
                      'Últimas ${DashboardStore.seriesLength} lecturas',
                      style: text.bodySmall?.copyWith(
                        color: palette.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedNumber(
                value: last,
                format: Fmt.money,
                style: AppTypography.mono(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Tones.info(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RepaintBoundary(
            child: LiveAreaChart(
              values: series,
              color: Tones.info(context),
              format: Fmt.money,
              height: 220,
              semanticLabel:
                  'Ingresos en tiempo real. Último valor ${Fmt.money(last)}, '
                  'máximo ${Fmt.money(max)}, mínimo ${Fmt.money(min)}.',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca o arrastra para ver un punto  ·  doble toque para limpiar',
            style: text.bodySmall?.copyWith(color: palette.mutedForeground),
          ),
        ],
      ),
    );
  }
}

// ─── Embudo y meta ───────────────────────────────────────────────────────

class _Funnel extends StatelessWidget {
  const _Funnel({required this.crm});

  final CrmController crm;

  @override
  Widget build(BuildContext context) {
    final store = crm.opportunities;
    final palette = AppPalette.of(context);
    final reduced = AppMotion.reduced(context);
    const stages = [
      OpportunityStage.open,
      OpportunityStage.qualified,
      OpportunityStage.meeting,
      OpportunityStage.proposal,
      OpportunityStage.negotiation,
      OpportunityStage.won,
    ];
    final max = stages
        .map(store.totalFor)
        .fold<double>(1, (a, b) => a > b ? a : b);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Embudo de oportunidades',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'Toca una etapa para ver sus oportunidades',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: palette.mutedForeground),
          ),
          const SizedBox(height: 8),
          for (final stage in stages)
            InkWell(
              key: ValueKey('funnel-${stage.name}'),
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                store.setStageFilter(stage);
                crm.open(CrmSection.opportunities);
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            opportunityIcon(stage),
                            size: 14,
                            color: opportunityColor(context, stage),
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: Text(stage.label)),
                          Text(
                            '${store.countFor(stage)}  ·  ${Fmt.money(store.totalFor(stage), compact: true)}',
                            style: AppTypography.mono(
                              fontSize: 12,
                              color: palette.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: reduced ? store.totalFor(stage) / max : 0,
                            end: store.totalFor(stage) / max,
                          ),
                          duration: reduced
                              ? Duration.zero
                              : const Duration(milliseconds: 800),
                          curve: AppMotion.out,
                          builder: (context, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 6,
                            color: opportunityColor(context, stage),
                            backgroundColor: palette.border,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Goal extends StatelessWidget {
  const _Goal({required this.store});

  final DashboardStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final percent = store.goalProgress * 100;
    final reached = store.goalProgress >= 1;
    return SurfaceCard(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Meta del periodo', style: text.titleMedium),
          ),
          const SizedBox(height: 16),
          RingGauge(
            progress: store.goalProgress,
            color: reached ? Tones.warning(context) : Tones.info(context),
            size: 150,
            stroke: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedNumber(
                  value: percent,
                  format: (v) => '${v.round()}%',
                  style: AppTypography.mono(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: palette.foreground,
                  ),
                ),
                Text(
                  'de ${Fmt.money(store.period.goal, compact: true)}',
                  style: text.bodySmall?.copyWith(
                    color: palette.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StatusChip(
            label: reached
                ? 'Meta superada'
                : 'Faltan ${Fmt.money(store.period.goal - store.revenue, compact: true)}',
            color: reached ? Tones.warning(context) : Tones.info(context),
            icon: reached ? Icons.emoji_events_outlined : Icons.flag_outlined,
          ),
        ],
      ),
    );
  }
}

// ─── Actividad ───────────────────────────────────────────────────────────

class _Feed extends StatelessWidget {
  const _Feed({required this.store});

  final DashboardStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final now = store.now;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actividad en vivo', style: text.titleMedium),
          const SizedBox(height: 4),
          AnimatedSize(
            duration: AppMotion.reduced(context)
                ? Duration.zero
                : AppMotion.base,
            curve: AppMotion.out,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                for (final event in store.feed)
                  _FeedItem(
                    key: ValueKey(event.id),
                    event: event,
                    age: _age(now.difference(event.at)),
                  ),
              ],
            ),
          ),
          if (store.feed.isEmpty)
            Text(
              'Sin actividad todavía.',
              style: text.bodySmall?.copyWith(color: palette.mutedForeground),
            ),
        ],
      ),
    );
  }

  static String _age(Duration d) {
    if (d.inSeconds < 5) return 'ahora';
    if (d.inSeconds < 60) return 'hace ${d.inSeconds} s';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    return 'hace ${d.inHours} h';
  }
}

class _FeedItem extends StatelessWidget {
  const _FeedItem({super.key, required this.event, required this.age});

  final ActivityEvent event;
  final String age;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final (icon, color) = switch (event.kind) {
      ActivityKind.payment => (Icons.payments_outlined, Tones.success(context)),
      ActivityKind.lead => (
        Icons.person_add_alt_1_outlined,
        Tones.info(context),
      ),
      ActivityKind.deal => (Icons.trending_up, Tones.warning(context)),
      ActivityKind.task => (Icons.task_alt, palette.mutedForeground),
    };
    final reduced = AppMotion.reduced(context);

    // Solo los eventos nuevos entran con animación: la clave conserva el estado.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reduced ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: AppMotion.out,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * -14),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: text.titleSmall?.copyWith(fontSize: 14),
                  ),
                  Text(
                    event.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: palette.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              age,
              style: AppTypography.mono(
                fontSize: 11,
                color: palette.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
