import 'package:flutter/material.dart';

import '../../animations/animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import 'lead.dart';
import 'lead_dialogs.dart';
import 'lead_widgets.dart';
import 'leads_store.dart';

import 'lead_feedback.dart';

class LeadTable extends StatelessWidget {
  const LeadTable({super.key, required this.leads, required this.store});

  final List<Lead> leads;
  final LeadsStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1040
            ? 1040.0
            : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            height: constraints.maxHeight,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: palette.border)),
                  ),
                  child: const _TableHeader(),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: leads.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: palette.border),
                    itemBuilder: (context, index) {
                      return FadeInWidget(
                        delay: _staggerDelay(index),
                        begin: const Offset(-0.04, 0),
                        child: _TableRow(lead: leads[index], store: store),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppPalette.of(context).mutedForeground,
      letterSpacing: 0.6,
      fontWeight: FontWeight.w600,
    );
    return Row(
      children: [
        Expanded(flex: 4, child: Text('NOMBRE', style: style)),
        Expanded(flex: 3, child: Text('EMPRESA', style: style)),
        Expanded(flex: 3, child: Text('EMAIL', style: style)),
        Expanded(flex: 2, child: Text('INTERÉS', style: style)),
        Expanded(flex: 4, child: Text('ETAPA', style: style)),
        Expanded(flex: 2, child: Text('RESPONSABLE', style: style)),
        const SizedBox(width: 40),
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.lead, required this.store});

  final Lead lead;
  final LeadsStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 4, child: _Identity(lead: lead)),
          Expanded(flex: 3, child: Text(lead.displayCompany)),
          Expanded(
            flex: 3,
            child: Text(
              lead.email,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.mono(
                fontSize: 13,
                color: palette.foreground,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: InterestBadge(interest: lead.interestValue),
            ),
          ),
          Expanded(
            flex: 4,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StageBadge(
                stage: lead.stageValue,
                onSelected: (stage) => reportLeadResult(
                  context,
                  store.changeStage(lead.id, stage),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              lead.displayAssignee,
              style: AppTypography.mono(
                fontSize: 13,
                color: palette.foreground,
              ),
            ),
          ),
          _Actions(lead: lead, store: store),
        ],
      ),
    );
  }
}

class LeadCards extends StatelessWidget {
  const LeadCards({super.key, required this.leads, required this.store});

  final List<Lead> leads;
  final LeadsStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: leads.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final lead = leads[index];
        return FadeInWidget(
          delay: _staggerDelay(index),
          begin: const Offset(0, 0.08),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: palette.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radius - 1),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 3,
                    child: ColoredBox(
                      color: stageColor(context, lead.stageValue),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(17, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _Identity(lead: lead)),
                            _Actions(lead: lead, store: store),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _MetaLine(label: 'Empresa', value: lead.displayCompany),
                        _MetaLine(
                          label: 'Email',
                          value: lead.email,
                          mono: true,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            InterestBadge(interest: lead.interestValue),
                            StageBadge(
                              stage: lead.stageValue,
                              onSelected: (stage) => reportLeadResult(
                                context,
                                store.changeStage(lead.id, stage),
                              ),
                            ),
                            Text(
                              lead.displayAssignee,
                              style: AppTypography.mono(
                                fontSize: 12,
                                color: palette.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Retraso de entrada con tope: pasado el octavo elemento todos aparecen
/// juntos, así una página larga no hace esperar a las últimas filas.
Duration _staggerDelay(int index) =>
    Duration(milliseconds: 45 * (index < 8 ? index : 8));

class _Identity extends StatelessWidget {
  const _Identity({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      children: [
        LeadAvatar(initials: lead.initials),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lead.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                lead.displayJobTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: palette.mutedForeground),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final valueStyle = mono
        ? AppTypography.mono(fontSize: 13, color: palette.mutedForeground)
        : Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: palette.mutedForeground);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.lead, required this.store});

  final Lead lead;
  final LeadsStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Más acciones',
      icon: Icon(Icons.more_horiz, color: palette.mutedForeground),
      onSelected: (action) => _run(context, action),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'view', child: Text('Ver detalles')),
        PopupMenuItem(value: 'edit', child: Text('Editar')),
        PopupMenuItem(value: 'convert', child: Text('Convertir a cliente')),
        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
      ],
    );
  }

  Future<void> _run(BuildContext context, String action) async {
    switch (action) {
      case 'view':
        final fresh = await store.fetchContact(lead.id);
        if (!context.mounted) return;
        if (fresh == null) {
          showLeadMessage(
            context,
            store.error ?? 'No se pudo abrir el contacto',
          );
          return;
        }
        await showLeadDetails(context, fresh);
      case 'edit':
        final edited = await showLeadForm(context, lead: lead);
        if (edited == null || !context.mounted) return;
        final message = await store.update(edited);
        if (!context.mounted || message == null) return;
        showLeadMessage(context, message);
      case 'convert':
        final message = await store.convertToClient(lead.id);
        if (!context.mounted) return;
        showLeadMessage(
          context,
          message ?? '${lead.fullName} ahora es cliente.',
        );
      case 'delete':
        final confirmed = await confirmDeleteLead(context, lead);
        if (!confirmed || !context.mounted) return;
        final message = await store.remove(lead.id);
        if (!context.mounted || message == null) return;
        showLeadMessage(context, message);
    }
  }
}
