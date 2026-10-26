import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'lead.dart';

class LeadDetailsDialog extends StatelessWidget {
  const LeadDetailsDialog({super.key, required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final rows = <(String, String)>[
      ('Tipo', lead.typeValue.label),
      ('Estado comercial', lead.statusValue.label),
      ('Email', _orDash(lead.email)),
      ('Teléfono', _orDash(lead.phone)),
      ('Móvil', _orDash(lead.mobile)),
      ('Web', _orDash(lead.web)),
      ('Empresa', lead.displayCompany),
      ('Cargo', lead.displayJobTitle),
      ('Industria', _orDash(lead.industry)),
      ('Dirección', _orDash(lead.address)),
      ('Ciudad', _orDash(lead.city)),
      ('Estado', _orDash(lead.state)),
      ('País', _orDash(lead.country)),
      ('C.P.', _orDash(lead.postal)),
      ('Origen', sourceLabel(lead.source)),
      ('Interés', lead.interestValue?.label ?? '—'),
      ('Calificación', _orDash(lead.qualification)),
      ('Etapa', lead.stageValue.label),
      ('Propietario', _orDash(lead.owner)),
      ('Responsable', _orDash(lead.assignee)),
      ('Notas', _orDash(lead.description)),
      ('Creado', lead.createdAt),
      ('Actualizado', lead.updatedAt),
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.fullName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          lead.displayJobTitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: palette.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: palette.border),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final (label, value) = rows[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: palette.mutedForeground),
                        ),
                      ),
                      Expanded(child: Text(value)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _orDash(String value) => value.trim().isEmpty ? '—' : value;
