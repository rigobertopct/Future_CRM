import '../../core/api/crm_client.dart';
import 'task.dart';

abstract class TasksApi {
  Future<List<Task>> list();

  Future<void> create(TaskDraft draft);

  /// `actualizar_tarea` conserva los campos que no se envían.
  Future<void> updateStatus(String id, TaskStatus status);

  Future<void> delete(String id);
}

class HttpTasksApi implements TasksApi {
  HttpTasksApi({required this._client});

  final CrmClient _client;

  @override
  Future<List<Task>> list() async {
    final envelope = await _client.post('tareas', {'exec': 'ok'});
    final datos = envelope.datos;
    if (datos is! List) return const [];
    return [
      for (final item in datos)
        if (item is Map) Task.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<void> create(TaskDraft draft) async {
    await _client.post('crear_tarea', draft.toDatos());
  }

  @override
  Future<void> updateStatus(String id, TaskStatus status) async {
    await _client.post('actualizar_tarea', {
      'id_tarea': id,
      'estado': status.raw,
    });
  }

  @override
  Future<void> delete(String id) async {
    await _client.post('eliminar_tarea', {'id_tarea': id});
  }
}
