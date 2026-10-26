import 'package:flutter/material.dart';

import '../../animations/animations.dart';
import '../../app/crm_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import 'lead.dart';
import 'lead_feedback.dart';
import 'lead_list.dart';
import 'leads_store.dart';

class LeadsPage extends StatelessWidget {
  const LeadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CrmScope.of(context).leads;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _buildPage(context, store),
    );
  }

  Widget _buildPage(BuildContext context, LeadsStore store) {
    final palette = AppPalette.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final items = store.pageItems;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeInWidget(child: _Header(store: store)),
          const SizedBox(height: 16),
          FadeInWidget(
            delay: const Duration(milliseconds: 70),
            child: _StageFilters(store: store),
          ),
          const SizedBox(height: 12),
          if (store.loading && store.total > 0) const LinearProgressIndicator(),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              child: AnimatedSwitcherHelper(
                switchKey: Object.hash(
                  store.loading,
                  store.error,
                  store.stageFilter,
                  store.page,
                  items.length,
                ),
                child: _LeadBody(wide: wide, items: items, store: store),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Pagination(store: store),
        ],
      ),
    );
  }
}

class _LeadBody extends StatelessWidget {
  const _LeadBody({
    required this.wide,
    required this.items,
    required this.store,
  });

  final bool wide;
  final List<Lead> items;
  final LeadsStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    if (store.loading && store.total == 0) {
      return const SkeletonList(semanticLabel: 'Cargando leads');
    }
    if (store.error != null && store.total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                store.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: palette.mutedForeground),
              ),
              const SizedBox(height: 12),
              ScaleOnPress(
                child: FilledButton(
                  onPressed: store.refresh,
                  child: const Text('Reintentar'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Ningún lead coincide con la búsqueda.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: palette.mutedForeground),
        ),
      );
    }
    return wide
        ? LeadTable(leads: items, store: store)
        : LeadCards(leads: items, store: store);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.store});

  final LeadsStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final compact = MediaQuery.sizeOf(context).width < 640;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Leads', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 2),
        Text(
          'Gestiona tu pipeline  ·  ${store.total} en total',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: palette.mutedForeground),
        ),
      ],
    );
    final button = ScaleOnPress(
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          shadows: AppEffects.glow(palette.primary),
        ),
        child: FilledButton.icon(
          key: const Key('create-lead'),
          onPressed: () => createLead(context, store),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Crear lead'),
          style: FilledButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 12), button],
      );
    }
    return Row(
      children: [
        Expanded(child: title),
        button,
      ],
    );
  }
}

class _StageFilters extends StatelessWidget {
  const _StageFilters({required this.store});

  final LeadsStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final selected = store.stageFilter;
    final active = selected != null;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: active ? palette.primary : palette.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  size: 16,
                  color: active ? palette.primary : palette.mutedForeground,
                ),
                const SizedBox(width: 8),
                Text(
                  'Etapa',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: palette.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 1, height: 18, color: palette.border),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<LeadStage?>(
                      key: const ValueKey('stage-filter'),
                      value: selected,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      dropdownColor: palette.card,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: palette.mutedForeground,
                      ),
                      iconSize: 20,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.foreground,
                        fontWeight: FontWeight.w500,
                      ),
                      hint: _StageOption(
                        label: 'Todos',
                        count: store.countFor(null),
                      ),
                      selectedItemBuilder: (context) => [
                        _StageOption(
                          label: 'Todos',
                          count: store.countFor(null),
                        ),
                        for (final stage in LeadStage.filters)
                          _StageOption(
                            label: stage.label,
                            count: store.countFor(stage),
                          ),
                      ],
                      items: [
                        DropdownMenuItem<LeadStage?>(
                          key: const ValueKey('filter-todos'),
                          value: null,
                          child: _StageOption(
                            label: 'Todos',
                            count: store.countFor(null),
                          ),
                        ),
                        for (final stage in LeadStage.filters)
                          DropdownMenuItem<LeadStage?>(
                            key: ValueKey('filter-${stage.name}'),
                            value: stage,
                            child: _StageOption(
                              label: stage.label,
                              count: store.countFor(stage),
                            ),
                          ),
                      ],
                      onChanged: store.setStageFilter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StageOption extends StatelessWidget {
  const _StageOption({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$count',
          style: AppTypography.mono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({required this.store});

  final LeadsStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final page = store.page + 1;
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Anterior',
              onPressed: store.page == 0
                  ? null
                  : () => store.setPage(store.page - 1),
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '$page  /  ${store.pageCount}',
              style: AppTypography.mono(
                fontSize: 13,
                color: palette.mutedForeground,
              ),
            ),
            IconButton(
              tooltip: 'Siguiente',
              onPressed: store.page >= store.pageCount - 1
                  ? null
                  : () => store.setPage(store.page + 1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
