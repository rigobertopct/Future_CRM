import 'package:flutter/foundation.dart';

import '../../core/api/crm_client.dart';
import 'task.dart';
import 'tasks_api.dart';

export 'task.dart';

enum TaskFilter {
  all('Todas'),
  today('Hoy'),
  overdue('Vencidas'),
  done('Completadas');

  const TaskFilter(this.label);

  final String label;
}

/// Tareas de la API (`tareas`) con filtros y búsqueda.
class TasksStore extends ChangeNotifier {
  TasksStore({required this._api, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final TasksApi _api;
  final DateTime Function() _clock;
  final List<Task> _items = [];

  /// Tareas quitadas de la lista cuyo borrado aún se puede deshacer. Una
  /// recarga no las vuelve a mostrar.
  final Set<String> _pendingRemovals = {};

  TaskFilter filter = TaskFilter.all;
  String _query = '';
  bool _loading = false;
  String? _error;
  int _generation = 0;
  bool _disposed = false;

  DateTime get now => _clock();
  String get query => _query;
  bool get loading => _loading;
  String? get error => _error;
  List<Task> get all => List.unmodifiable(_items);

  DateTime get _today {
    final now = this.now;
    return DateTime(now.year, now.month, now.day);
  }

  bool isOverdue(Task t) => !t.done && t.due != null && t.due!.isBefore(_today);

  bool isToday(Task t) {
    final due = t.due;
    final now = this.now;
    return due != null &&
        due.year == now.year &&
        due.month == now.month &&
        due.day == now.day;
  }

  bool _matches(Task t, TaskFilter f) => switch (f) {
    TaskFilter.all => !t.done,
    TaskFilter.today => !t.done && isToday(t),
    TaskFilter.overdue => isOverdue(t),
    TaskFilter.done => t.done,
  };

  /// Por fecha (las que no tienen van al final) y luego por prioridad.
  List<Task> get visible {
    final q = _query.toLowerCase();
    final list = _items.where((t) {
      if (!_matches(t, filter)) return false;
      if (q.isEmpty) return true;
      return t.title.toLowerCase().contains(q) ||
          t.contact.toLowerCase().contains(q);
    }).toList();
    list.sort((a, b) {
      final byDate = _compareDates(a.due, b.due);
      if (byDate != 0) return byDate;
      return b.priority.index.compareTo(a.priority.index);
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

  /// Recarga las tareas. Una carga nueva descarta la anterior.
  Future<void> refresh() async {
    final generation = ++_generation;
    _loading = true;
    _error = null;
    _notify();
    try {
      final loaded = await _api.list();
      if (generation != _generation) return;
      _items
        ..clear()
        ..addAll(loaded.where((t) => !_pendingRemovals.contains(t.id)));
    } catch (error) {
      if (generation != _generation) return;
      _error = _message(error);
    } finally {
      if (generation == _generation) {
        _loading = false;
        _notify();
      }
    }
  }

  /// Marca la tarea como completada o pendiente al momento y lo deshace si la
  /// API lo rechaza. Devuelve el mensaje de error, o `null`.
  Future<String?> toggle(String id) async {
    final index = _items.indexWhere((t) => t.id == id);
    if (index < 0) return 'No se encontró la tarea';
    final previous = _items[index];
    final status = previous.done ? TaskStatus.pending : TaskStatus.completed;

    _items[index] = previous.copyWith(status: status);
    _notify();
    try {
      await _api.updateStatus(id, status);
      return null;
    } catch (error) {
      final current = _items.indexWhere((t) => t.id == id);
      if (current >= 0) _items[current] = previous;
      _notify();
      return _message(error);
    }
  }

  /// Crea la tarea y recarga la lista para recibir su id y su contacto.
  Future<String?> add(TaskDraft draft) async {
    try {
      await _api.create(draft);
    } catch (error) {
      return _message(error);
    }
    await refresh();
    return null;
  }

  /// Quita la tarea de la lista y la devuelve para poder deshacer. El borrado
  /// en la API ocurre en [commitRemoval].
  Task? remove(String id) {
    final index = _items.indexWhere((t) => t.id == id);
    if (index < 0) return null;
    final removed = _items.removeAt(index);
    _pendingRemovals.add(id);
    _notify();
    return removed;
  }

  void restore(Task task) {
    _pendingRemovals.remove(task.id);
    if (_items.any((t) => t.id == task.id)) return;
    _items.insert(0, task);
    _notify();
  }

  /// Borra en la API una tarea quitada con [remove]. Si falla, la tarea
  /// vuelve a la lista y se devuelve el mensaje de error.
  Future<String?> commitRemoval(Task task) async {
    if (!_pendingRemovals.contains(task.id)) return null;
    try {
      await _api.delete(task.id);
      _pendingRemovals.remove(task.id);
      return null;
    } catch (error) {
      restore(task);
      return _message(error);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  static int _compareDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  static String _message(Object error) {
    if (error is CrmApiException) return error.message;
    return 'No se pudo conectar con el servidor';
  }
}
