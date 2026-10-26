import 'package:flutter/foundation.dart';

/// Etapas de `crear_oportunidad` / `actualizar_etapa_oportunidad`.
///
/// [probability] solo se usa cuando la API no envía `probabilidad`.
enum OpportunityStage {
  open('nueva', 'Nueva', 0.1),
  qualified('calificada', 'Calificada', 0.25),
  meeting('reunion', 'Reunión', 0.4),
  proposal('propuesta', 'Propuesta', 0.55),
  negotiation('negociacion', 'Negociación', 0.8),
  won('ganada', 'Ganada', 1),
  lost('perdida', 'Perdida', 0),
  cancelled('cancelada', 'Cancelada', 0);

  const OpportunityStage(this.raw, this.label, this.probability);

  final String raw;
  final String label;
  final double probability;

  bool get isOpen => this != won && this != lost && this != cancelled;

  /// Siguiente etapa del embudo, o `null` si ya está cerrada.
  OpportunityStage? get next => switch (this) {
    open => qualified,
    qualified => meeting,
    meeting => proposal,
    proposal => negotiation,
    negotiation => won,
    won || lost || cancelled => null,
  };

  static OpportunityStage parse(String raw) {
    final value = raw.trim().toLowerCase();
    return OpportunityStage.values.firstWhere(
      (stage) => stage.raw == value,
      orElse: () => OpportunityStage.open,
    );
  }
}

/// `tipo_pago` de la oportunidad. [none] es el valor vacío de la API.
enum PaymentType {
  none('', 'Sin definir'),
  fixed('oferta fija', 'Oferta fija'),
  hourly('tarifa por hora', 'Tarifa por hora'),
  daily('pago diario', 'Pago diario'),
  weekly('pago semanal', 'Pago semanal'),
  monthly('pago mensual', 'Pago mensual'),
  yearly('pago anual', 'Pago anual');

  const PaymentType(this.raw, this.label);

  final String raw;
  final String label;

  static PaymentType parse(String raw) {
    final value = raw.trim().toLowerCase();
    return PaymentType.values.firstWhere(
      (type) => type.raw == value,
      orElse: () => PaymentType.none,
    );
  }
}

/// Registro de `pipelines`: un cambio de etapa de la oportunidad.
@immutable
class PipelineEntry {
  const PipelineEntry({required this.stage, required this.note, this.at});

  /// La API repite cada campo con clave numérica; solo se leen los nombres.
  factory PipelineEntry.fromJson(Map<String, dynamic> json) {
    return PipelineEntry(
      stage: OpportunityStage.parse(_text(json['etapa'])),
      note: _text(json['nota']).trim(),
      at: DateTime.tryParse(_text(json['creado'])),
    );
  }

  final OpportunityStage stage;
  final String note;
  final DateTime? at;
}

/// Contacto al que se puede asociar una oportunidad (`id_contacto`).
@immutable
class OpportunityContact {
  const OpportunityContact({
    required this.id,
    required this.name,
    this.company = '',
  });

  factory OpportunityContact.fromJson(Map<String, dynamic> json) {
    final name = '${_text(json['nombre'])} ${_text(json['apellidos'])}'.trim();
    return OpportunityContact(
      id: _text(json['id']),
      name: name.isEmpty ? 'Sin nombre' : name,
      company: _text(json['organizacion']),
    );
  }

  final String id;
  final String name;
  final String company;

  String get label => company.isEmpty ? name : '$name · $company';
}

@immutable
class Opportunity {
  const Opportunity({
    required this.id,
    required this.contactId,
    required this.name,
    required this.company,
    required this.amount,
    required this.stage,
    required this.owner,
    this.probability,
    this.closeDate,
    this.description = '',
    this.note = '',
    this.paymentType = PaymentType.none,
  });

  /// Registro de `oportunidades` / `oportunidad`. `valor` y `probabilidad`
  /// llegan como texto y pueden venir vacíos.
  factory Opportunity.fromJson(Map<String, dynamic> json) {
    final probability = double.tryParse(_text(json['probabilidad']));
    return Opportunity(
      id: _text(json['id']),
      contactId: _text(json['contacto']),
      name: _text(json['nombre']),
      company: _text(json['empresa']),
      amount: double.tryParse(_text(json['valor'])) ?? 0,
      stage: OpportunityStage.parse(_text(json['etapa'])),
      owner: _text(json['responsable']),
      probability: probability == null
          ? null
          : (probability / 100).clamp(0, 1).toDouble(),
      closeDate: DateTime.tryParse(_text(json['cierre'])),
      description: _text(json['descripcion']),
      note: _text(json['nota']),
      paymentType: PaymentType.parse(_text(json['tipo_pago'])),
    );
  }

  final String id;
  final String contactId;
  final String name;
  final String company;
  final double amount;
  final OpportunityStage stage;
  final String owner;

  /// Probabilidad de cierre (0–1) enviada por la API.
  final double? probability;
  final DateTime? closeDate;
  final String description;
  final String note;
  final PaymentType paymentType;

  /// Probabilidad efectiva: la de la API o, si falta, la de la etapa.
  /// Las oportunidades cerradas siempre usan la de su etapa.
  double get chance =>
      stage.isOpen ? (probability ?? stage.probability) : stage.probability;

  double get weighted => amount * chance;

  /// [closeDate] se pasa como función para poder dejarla en `null`.
  Opportunity copyWith({
    OpportunityStage? stage,
    String? name,
    String? company,
    double? amount,
    String? owner,
    double? Function()? probability,
    DateTime? Function()? closeDate,
    String? description,
    String? note,
    PaymentType? paymentType,
  }) => Opportunity(
    id: id,
    contactId: contactId,
    name: name ?? this.name,
    company: company ?? this.company,
    amount: amount ?? this.amount,
    stage: stage ?? this.stage,
    owner: owner ?? this.owner,
    probability: probability != null ? probability() : this.probability,
    closeDate: closeDate != null ? closeDate() : this.closeDate,
    description: description ?? this.description,
    note: note ?? this.note,
    paymentType: paymentType ?? this.paymentType,
  );

  /// Datos de `actualizar_oportunidad`. La API conserva los campos que no se
  /// envían. `cierre` no se puede borrar (vacío da error 500 y `null` se
  /// ignora), así que sin fecha no se envía.
  Map<String, dynamic> toUpdateDatos() {
    final chance = probability;
    return {
      'id_oportunidad': id,
      'nombre': name,
      'empresa': company,
      'valor': _number(amount),
      'probabilidad': chance == null ? '' : _number(chance * 100),
      'responsable': owner,
      'tipo_pago': paymentType.raw,
      'descripcion': description,
      'nota': note,
      if (closeDate != null) 'cierre': apiDate(closeDate!),
    };
  }
}

/// Fecha en el formato que acepta la API (`AAAA-MM-DD`).
String apiDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

/// Datos de `crear_oportunidad`. `id_contacto`, `nombre` y `etapa` son
/// obligatorios.
@immutable
class OpportunityDraft {
  const OpportunityDraft({
    required this.contactId,
    required this.name,
    required this.company,
    required this.amount,
    this.owner = '',
    this.stage = OpportunityStage.open,
  });

  final String contactId;
  final String name;
  final String company;
  final double amount;
  final String owner;
  final OpportunityStage stage;

  Map<String, dynamic> toDatos() {
    return {
      'id_contacto': contactId,
      'nombre': name,
      'etapa': stage.raw,
      'empresa': company,
      'valor': _number(amount),
      'probabilidad': _number(stage.probability * 100),
      'responsable': owner,
    };
  }
}

String _text(Object? value) => value == null ? '' : value.toString();

String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();
