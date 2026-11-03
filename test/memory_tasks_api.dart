import 'package:future_crm/core/api/crm_client.dart';
import 'package:future_crm/features/tasks/task.dart';
import 'package:future_crm/features/tasks/tasks_api.dart';

/// API de tareas en memoria. Los indicadores `fail*` hacen fallar cada
/// petición para probar los estados de error.
class MemoryTasksApi implements TasksApi {
  MemoryTasksApi({List<Task>? seed, DateTime? now})
    : _items = List.of(seed ?? sampleTasks(now ?? DateTime.now()));

  final List<Task> _items;
  bool failList = false;
  bool failUpdate = false;
  bool failCreate = false;
  bool failDelete = false;
  int _nextId = 100;

  final List<TaskDraft> created = [];
  final List<String> deleted = [];

  @override
  Future<List<Task>> list() async {
    if (failList) throw CrmApiException('Fallo de red');
    return List.of(_items);
  }

  @override
  Future<void> create(TaskDraft draft) async {
    if (failCreate) throw CrmApiException('No se pudo crear la tarea');
    created.add(draft);
    _items.add(
      Task(
        id: 'tk-${_nextId++}',
        title: draft.title,
        type: draft.type,
        priority: draft.priority,
        due: draft.due,
      ),
    );
  }

  @override
  Future<void> updateStatus(String id, TaskStatus status) async {
    if (failUpdate) throw CrmApiException('No se pudo guardar la tarea');
    final index = _items.indexWhere((t) => t.id == id);
    if (index >= 0) _items[index] = _items[index].copyWith(status: status);
  }

  @override
  Future<void> delete(String id) async {
    if (failDelete) throw CrmApiException('No se pudo eliminar la tarea');
    deleted.add(id);
    _items.removeWhere((t) => t.id == id);
  }
}

List<Task> sampleTasks(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  Task task(
    int n,
    String title,
    int days,
    TaskPriority p,
    String contact, {
    bool done = false,
  }) => Task(
    id: 'tk-$n',
    title: title,
    due: today.add(Duration(days: days)),
    priority: p,
    contact: contact,
    status: done ? TaskStatus.completed : TaskStatus.pending,
  );
  const high = TaskPriority.high;
  const mid = TaskPriority.medium;
  const low = TaskPriority.low;
  return [
    task(1, 'Enviar propuesta final a Nexora Labs', 0, high, 'Nexora Labs'),
    task(2, 'Llamada de seguimiento con Veltrix', 0, high, 'Veltrix'),
    task(3, 'Preparar demo de analítica', 1, mid, 'Grupo Aurelia'),
    task(4, 'Revisar contrato de renovación', -2, high, 'Solaris Energía'),
    task(5, 'Actualizar datos de contacto', -1, low, 'Kairos Retail'),
    task(6, 'Agendar reunión trimestral', 3, mid, 'Orbita Fintech'),
    task(7, 'Cotizar integración ERP', 2, mid, 'Altamar Foods'),
    task(8, 'Responder consulta de soporte', 0, low, 'Brisa Hoteles'),
    task(9, 'Enviar recordatorio de factura F-2041', -3, high, 'Lumen Salud'),
    task(10, 'Documentar requisitos del portal', 5, low, 'Kairos Retail'),
    task(11, 'Cerrar acta de la reunión', -1, mid, 'Aurelia', done: true),
    task(12, 'Compartir caso de éxito', -4, low, 'Zenit Motors', done: true),
    task(13, 'Validar acceso de usuarios', 0, mid, 'Montalvo', done: true),
  ];
}
