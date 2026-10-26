import 'package:flutter/material.dart';

import '../../animations/animations.dart';
import '../../app/crm_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/format.dart';
import '../../shared/widgets/chip_filter_bar.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/mini_charts.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/quick_form.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/surface_card.dart';
import 'tasks_store.dart';

const _dueOptions = {'Hoy': 0, 'Mañana': 1, 'En 3 días': 3, 'En 1 semana': 7};

Color _priorityColor(BuildContext context, TaskPriority priority) {
  final palette = AppPalette.of(context);
  return switch (priority) {
    TaskPriority.high => palette.destructive,
    TaskPriority.medium => Tones.warning(context),
    TaskPriority.low => palette.mutedForeground,
  };
}

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CrmScope.of(context).tasks;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _build(context, store),
    );
  }

  Widget _build(BuildContext context, TasksStore store) {
    final items = store.visible;
    return PageFrame(
      title: 'Tareas',
      subtitle:
          '${store.pendingCount} pendientes  ·  ${(store.completionRate * 100).round()}% completado',
      action: ScaleOnPress(
        child: FilledButton.icon(
          key: const ValueKey('create-task'),
          style: FilledButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: const Size(48, 48),
          ),
          onPressed: () => _create(context, store),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nueva tarea'),
        ),
      ),
      filters: ChipFilterBar<TaskFilter>(
        selected: store.filter,
        onSelected: store.setFilter,
        options: [
          for (final f in TaskFilter.values)
            FilterOption(f, f.label, count: store.countFor(f)),
        ],
      ),
      child: items.isEmpty
          ? EmptyState(
              icon: store.filter == TaskFilter.done
                  ? Icons.inbox_outlined
                  : Icons.task_alt,
              title: store.filter == TaskFilter.overdue
                  ? 'Nada vencido'
                  : 'Sin tareas aquí',
              message: store.filter == TaskFilter.all
                  ? 'Crea una tarea para empezar.'
                  : 'No hay tareas que coincidan con este filtro.',
              actionLabel: store.filter == TaskFilter.all ? null : 'Ver todas',
              onAction: () => store.setFilter(TaskFilter.all),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) return _Progress(store: store);
                final task = items[index - 1];
                return FadeInWidget(
                  key: ValueKey(task.id),
                  delay: Duration(milliseconds: 40 * (index < 8 ? index : 8)),
                  child: _TaskTile(task: task, store: store),
                );
              },
            ),
    );
  }

  Future<void> _create(BuildContext context, TasksStore store) async {
    final values = await showQuickForm(
      context,
      title: 'Nueva tarea',
      submitLabel: 'Crear tarea',
      fields: [
        const FieldSpec('title', 'Título'),
        const FieldSpec('related', 'Cuenta u oportunidad', required: false),
        FieldSpec(
          'priority',
          'Prioridad',
          options: [for (final p in TaskPriority.values) p.label],
          initial: TaskPriority.medium.label,
        ),
        FieldSpec('due', 'Vence', options: _dueOptions.keys.toList()),
      ],
    );
    if (values == null || !context.mounted) return;
    store.add(
      title: values['title']!,
      related: values['related']!.isEmpty ? 'General' : values['related']!,
      priority: TaskPriority.values.firstWhere(
        (p) => p.label == values['priority'],
      ),
      dueInDays: _dueOptions[values['due']]!,
    );
    showMessage(context, 'Tarea creada.');
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.store});

  final TasksStore store;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final done = store.countFor(TaskFilter.done);
    return SurfaceCard(
      child: Row(
        children: [
          RingGauge(
            progress: store.completionRate,
            color: Tones.success(context),
            size: 56,
            stroke: 5,
            child: Text(
              '${(store.completionRate * 100).round()}',
              style: AppTypography.mono(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: palette.foreground,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Avance del equipo', style: text.titleMedium),
                Text(
                  '$done completadas  ·  ${store.countFor(TaskFilter.overdue)} vencidas',
                  style: text.bodySmall?.copyWith(
                    color: palette.mutedForeground,
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

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.store});

  final Task task;
  final TasksStore store;

  void _delete(BuildContext context) {
    final removed = store.remove(task.id);
    if (removed == null) return;
    showUndoBar(
      context,
      message: '¿Confirmas la eliminación de la tarea "${removed.title}"?',
      onUndo: () => store.restore(removed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final overdue = store.isOverdue(task);
    final priorityColor = _priorityColor(context, task.priority);
    final dueColor = overdue ? palette.destructive : palette.mutedForeground;
    final duration = AppMotion.reduced(context)
        ? Duration.zero
        : AppMotion.base;

    return Dismissible(
      key: ValueKey('dismiss-${task.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(context),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: palette.destructive.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: palette.destructive),
      ),
      child: SurfaceCard(
        accent: task.done ? null : priorityColor,
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Row(
          children: [
            Semantics(
              label: task.done
                  ? 'Marcar como pendiente'
                  : 'Marcar como completada',
              child: IconButton(
                key: ValueKey('toggle-${task.id}'),
                onPressed: () => store.toggle(task.id),
                icon: AnimatedSwitcher(
                  duration: duration,
                  transitionBuilder: (child, a) =>
                      ScaleTransition(scale: a, child: child),
                  child: Icon(
                    task.done
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    key: ValueKey(task.done),
                    color: task.done
                        ? Tones.success(context)
                        : palette.mutedForeground,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    style: (text.titleMedium ?? const TextStyle()).copyWith(
                      color: task.done
                          ? palette.mutedForeground
                          : palette.foreground,
                      decoration: task.done ? TextDecoration.lineThrough : null,
                    ),
                    child: Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusChip(
                        label: task.priority.label,
                        color: priorityColor,
                        icon: Icons.flag_outlined,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            overdue ? Icons.error_outline : Icons.schedule,
                            size: 13,
                            color: dueColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Fmt.relativeDay(task.due, store.now),
                            style: AppTypography.mono(
                              fontSize: 12,
                              color: dueColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        task.related,
                        style: text.bodySmall?.copyWith(
                          color: palette.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Más acciones',
              icon: Icon(Icons.more_horiz, color: palette.mutedForeground),
              onSelected: (value) {
                if (value == 'delete') _delete(context);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
