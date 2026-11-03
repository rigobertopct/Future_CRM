import 'package:flutter/foundation.dart';

enum TaskPriority {
  low('baja', 'Baja'),
  medium('media', 'Media'),
  high('alta', 'Alta');

  const TaskPriority(this.raw, this.label);

  /// Valor que usa la API.
  final String raw;
  final String label;

  static TaskPriority parse(String value) => values.firstWhere(
    (p) => p.raw == value.trim().toLowerCase(),
    orElse: () => medium,
  );
}

enum TaskType {
  request('solicitud', 'Solicitud'),
  email('email', 'Email'),
  followUp('seguimiento', 'Seguimiento'),
  meeting('reunion', 'Reunión'),
  call('llamada', 'Llamada'),
  other('otro', 'Otro');

  const TaskType(this.raw, this.label);

  final String raw;
  final String label;

  /// Los datos de prueba del servidor aún usan `correo` en lugar de `email`.
  static TaskType parse(String value) {
    final raw = value.trim().toLowerCase();
    if (raw == 'correo') return email;
    return values.firstWhere((t) => t.raw == raw, orElse: () => other);
  }
}

enum TaskStatus {
  pending('pendiente', 'Pendiente'),
  inProgress('en curso', 'En curso'),
  completed('completada', 'Completada'),
  postponed('aplazada', 'Aplazada'),
  onHold('en espera', 'En espera'),
  cancelled('cancelada', 'Cancelada');

  const TaskStatus(this.raw, this.label);

  final String raw;
  final String label;

  /// Completadas y canceladas ya no cuentan como pendientes.
  bool get isClosed => this == completed || this == cancelled;

  /// Acepta también los valores de la versión anterior del documento.
  static TaskStatus parse(String value) => switch (value.trim().toLowerCase()) {
    'no iniciada' => pending,
    'finalizada' => completed,
    final raw => values.firstWhere((s) => s.raw == raw, orElse: () => pending),
  };
}

@immutable
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.priority,
    this.type = TaskType.other,
    this.status = TaskStatus.pending,
    this.due,
    this.contact = '',
  });

  /// Registro de `tareas` / `tarea`. `contacto` llega con el nombre del
  /// contacto; las fechas vienen como `AAAA-MM-DD HH:MM:SS` o vacías.
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: _text(json['id']),
    title: _text(json['nombre']),
    type: TaskType.parse(_text(json['tipo'])),
    status: TaskStatus.parse(_text(json['estado'])),
    priority: TaskPriority.parse(_text(json['prioridad'])),
    due: DateTime.tryParse(_text(json['fecha_cumplimiento'])),
    contact: _text(json['contacto']),
  );

  final String id;
  final String title;
  final TaskType type;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? due;

  /// Nombre del contacto, vacío si la tarea no tiene.
  final String contact;

  bool get done => status.isClosed;

  Task copyWith({TaskStatus? status}) => Task(
    id: id,
    title: title,
    type: type,
    status: status ?? this.status,
    priority: priority,
    due: due,
    contact: contact,
  );
}

/// Datos de `crear_tarea`. `nombre`, `tipo` y `estado` son obligatorios.
@immutable
class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.type,
    required this.priority,
    this.due,
    this.contactId,
  });

  final String title;
  final TaskType type;
  final TaskPriority priority;
  final DateTime? due;
  final String? contactId;

  Map<String, dynamic> toDatos() => {
    'nombre': title,
    'tipo': type.raw,
    'estado': TaskStatus.pending.raw,
    'prioridad': priority.raw,
    if (due != null) 'fecha_cumplimiento': apiDateTime(due!),
    if (contactId != null) 'id_contacto': contactId,
  };
}

/// Fecha y hora en el formato con el que responde la API.
String apiDateTime(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} '
      '${two(date.hour)}:${two(date.minute)}:${two(date.second)}';
}

String _text(Object? value) => value == null ? '' : value.toString();
