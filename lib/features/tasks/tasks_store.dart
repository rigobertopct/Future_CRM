import 'package:flutter/foundation.dart';

enum TaskPriority {
  low('Baja'),
  medium('Media'),
  high('Alta');

  const TaskPriority(this.label);

  final String label;
}

enum TaskFilter {
  all('Todas'),
  today('Hoy'),
  overdue('Vencidas'),
  done('Completadas');

  const TaskFilter(this.label);

  final String label;
}

@immutable
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.due,
    required this.priority,
    required this.related,
    this.done = false,
  });

  final String id;
  final String title;
  final DateTime due;
  final TaskPriority priority;

  /// Cuenta u oportunidad a la que pertenece la tarea.
  final String related;
  final bool done;

  Task copyWith({bool? done}) => Task(
    id: id,
    title: title,
    due: due,
    priority: priority,
    related: related,
    done: done ?? this.done,
  );
}

class TasksStore extends ChangeNotifier {
  TasksStore({DateTime? now, List<Task>? seed}) : _now = now ?? DateTime.now() {
    _items = List.of(seed ?? _sample(_now));
    _nextId = _items.length + 1;
  }

  final DateTime _now;
  late List<Task> _items;
  late int _nextId;

  TaskFilter filter = TaskFilter.all;
  String _query = '';

  DateTime get now => _now;
  String get query => _query;

  DateTime get _today => DateTime(_now.year, _now.month, _now.day);

  bool isOverdue(Task t) => !t.done && t.due.isBefore(_today);

  bool isToday(Task t) =>
      t.due.year == _now.year &&
      t.due.month == _now.month &&
      t.due.day == _now.day;

  bool _matches(Task t, TaskFilter f) => switch (f) {
    TaskFilter.all => !t.done,
    TaskFilter.today => !t.done && isToday(t),
    TaskFilter.overdue => isOverdue(t),
    TaskFilter.done => t.done,
  };

  List<Task> get visible {
    final q = _query.toLowerCase();
    final list = _items.where((t) {
      if (!_matches(t, filter)) return false;
      if (q.isEmpty) return true;
      return t.title.toLowerCase().contains(q) ||
          t.related.toLowerCase().contains(q);
    }).toList();
    list.sort((a, b) {
      final byPriority = b.priority.index.compareTo(a.priority.index);
      return a.due == b.due ? byPriority : a.due.compareTo(b.due);
    });
    return list;
  }

  int countFor(TaskFilter f) => _items.where((t) => _matches(t, f)).length;

  int get pendingCount => _items.where((t) => !t.done).length;

  double get completionRate =>
      _items.isEmpty ? 0 : _items.where((t) => t.done).length / _items.length;

  void setFilter(TaskFilter value) {
    if (filter == value) return;
    filter = value;
    notifyListeners();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void toggle(String id) {
    final index = _items.indexWhere((t) => t.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(done: !_items[index].done);
    notifyListeners();
  }

  Task add({
    required String title,
    required TaskPriority priority,
    required int dueInDays,
    String related = 'General',
  }) {
    final created = Task(
      id: 'tk-${_nextId++}',
      title: title,
      due: _today.add(Duration(days: dueInDays)),
      priority: priority,
      related: related,
    );
    _items.insert(0, created);
    notifyListeners();
    return created;
  }

  /// Elimina la tarea y la devuelve para poder deshacer.
  Task? remove(String id) {
    final index = _items.indexWhere((t) => t.id == id);
    if (index < 0) return null;
    final removed = _items.removeAt(index);
    notifyListeners();
    return removed;
  }

  void restore(Task task) {
    if (_items.any((t) => t.id == task.id)) return;
    _items.insert(0, task);
    notifyListeners();
  }

  static List<Task> _sample(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    Task task(
      int n,
      String title,
      int days,
      TaskPriority p,
      String related, {
      bool done = false,
    }) => Task(
      id: 'tk-$n',
      title: title,
      due: today.add(Duration(days: days)),
      priority: p,
      related: related,
      done: done,
    );
    const high = TaskPriority.high;
    const mid = TaskPriority.medium;
    const low = TaskPriority.low;
    return [
      task(1, 'Enviar propuesta final a Nexora Labs', 0, high, 'Nexora Labs'),
      task(
        2,
        'Llamada de seguimiento con Veltrix',
        0,
        high,
        'Veltrix Logística',
      ),
      task(3, 'Preparar demo de analítica', 1, mid, 'Grupo Aurelia'),
      task(4, 'Revisar contrato de renovación', -2, high, 'Solaris Energía'),
      task(5, 'Actualizar datos de contacto', -1, low, 'Kairos Retail'),
      task(6, 'Agendar reunión trimestral', 3, mid, 'Orbita Fintech'),
      task(7, 'Cotizar integración ERP', 2, mid, 'Altamar Foods'),
      task(8, 'Responder consulta de soporte', 0, low, 'Brisa Hoteles'),
      task(9, 'Enviar recordatorio de factura F-2041', -3, high, 'Lumen Salud'),
      task(10, 'Documentar requisitos del portal', 5, low, 'Kairos Retail'),
      task(
        11,
        'Cerrar acta de la reunión del lunes',
        -1,
        mid,
        'Grupo Aurelia',
        done: true,
      ),
      task(12, 'Compartir caso de éxito', -4, low, 'Zenit Motors', done: true),
      task(
        13,
        'Validar acceso de usuarios nuevos',
        0,
        mid,
        'Montalvo & Asoc.',
        done: true,
      ),
    ];
  }
}
