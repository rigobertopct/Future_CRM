enum LeadStage {
  notContacted('abierto - no se ha contactado', 'Sin contactar'),
  attempted('abierto - se intento contactar', 'Intento'),
  contacted('abierto - contactado', 'Contactado'),
  disqualified('cerrado - descalificado', 'Descalificado'),
  converted('cerrado - convertido', 'Convertido');

  const LeadStage(this.raw, this.label);

  final String raw;
  final String label;

  static const List<LeadStage> filters = LeadStage.values;

  static LeadStage parse(String raw) {
    return LeadStage.values.firstWhere(
      (stage) => stage.raw == raw,
      orElse: () => LeadStage.notContacted,
    );
  }
}

enum LeadInterest {
  low('bajo', 'Bajo'),
  medium('medio', 'Medio'),
  high('alto', 'Alto');

  const LeadInterest(this.raw, this.label);

  final String raw;
  final String label;

  static LeadInterest? parse(String raw) {
    for (final interest in LeadInterest.values) {
      if (interest.raw == raw) return interest;
    }
    return null;
  }
}

enum LeadType {
  person('persona', 'Persona'),
  company('empresa', 'Empresa');

  const LeadType(this.raw, this.label);

  final String raw;
  final String label;

  static LeadType parse(String raw) {
    return LeadType.values.firstWhere(
      (type) => type.raw == raw,
      orElse: () => LeadType.person,
    );
  }
}

enum CommercialStatus {
  lead('lead', 'Lead'),
  prospect('prospecto', 'Prospecto'),
  client('cliente', 'Cliente');

  const CommercialStatus(this.raw, this.label);

  final String raw;
  final String label;

  static CommercialStatus parse(String raw) {
    return CommercialStatus.values.firstWhere(
      (status) => status.raw == raw,
      orElse: () => CommercialStatus.lead,
    );
  }
}

const leadSourceOptions = [
  'Web',
  'LinkedIn',
  'Referido',
  'Evento',
  'Llamada fría',
  'Anuncios',
  'Webinar',
];

String sourceLabel(String source) {
  return switch (source) {
    'web' => 'Web',
    'email' => 'Email',
    'redes sociales' => 'Redes sociales',
    'publicidad' => 'Publicidad',
    'evento' => 'Evento',
    '' => '—',
    _ => source,
  };
}

class Lead {
  const Lead({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.mobile,
    required this.company,
    required this.jobTitle,
    required this.industry,
    required this.web,
    required this.city,
    required this.state,
    required this.country,
    required this.address,
    required this.postal,
    required this.description,
    required this.source,
    required this.interest,
    required this.qualification,
    required this.commercialStatus,
    required this.stage,
    required this.type,
    required this.owner,
    required this.assignee,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String mobile;
  final String company;
  final String jobTitle;
  final String industry;
  final String web;
  final String city;
  final String state;
  final String country;
  final String address;
  final String postal;
  final String description;
  final String source;
  final String interest;
  final String qualification;
  final String commercialStatus;
  final String stage;
  final String type;
  final String owner;
  final String assignee;
  final String createdAt;
  final String updatedAt;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isEmpty ? '' : firstName[0];
    final last = lastName.isEmpty ? '' : lastName[0];
    final value = '$first$last'.toUpperCase();
    return value.isEmpty ? '?' : value;
  }

  String get displayCompany => _orDash(company);

  String get displayJobTitle => _orDash(jobTitle);

  String get displayAssignee {
    final value = assignee.trim().isNotEmpty ? assignee : owner;
    return _orDash(value);
  }

  LeadStage get stageValue => LeadStage.parse(stage);

  LeadInterest? get interestValue => LeadInterest.parse(interest);

  LeadType get typeValue => LeadType.parse(type);

  CommercialStatus get statusValue => CommercialStatus.parse(commercialStatus);

  Lead copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? mobile,
    String? company,
    String? jobTitle,
    String? industry,
    String? web,
    String? city,
    String? state,
    String? country,
    String? address,
    String? postal,
    String? description,
    String? source,
    String? interest,
    String? qualification,
    String? commercialStatus,
    String? stage,
    String? type,
    String? owner,
    String? assignee,
    String? createdAt,
    String? updatedAt,
  }) {
    return Lead(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      industry: industry ?? this.industry,
      web: web ?? this.web,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      address: address ?? this.address,
      postal: postal ?? this.postal,
      description: description ?? this.description,
      source: source ?? this.source,
      interest: interest ?? this.interest,
      qualification: qualification ?? this.qualification,
      commercialStatus: commercialStatus ?? this.commercialStatus,
      stage: stage ?? this.stage,
      type: type ?? this.type,
      owner: owner ?? this.owner,
      assignee: assignee ?? this.assignee,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: _text(json['id']),
      firstName: _text(json['nombre']),
      lastName: _text(json['apellidos']),
      email: _text(json['email']),
      phone: _text(json['telefono']),
      mobile: _text(json['movil']),
      company: _text(json['organizacion']),
      jobTitle: _text(json['cargo']),
      industry: _text(json['industria']),
      web: _text(json['web']),
      city: _text(json['ciudad']),
      state: _text(json['estado']),
      country: _text(json['pais']),
      address: _text(json['direccion']),
      postal: _text(json['postal']),
      description: _text(json['descripcion']),
      source: _text(json['origen']),
      interest: _text(json['interes']).toLowerCase(),
      qualification: _text(json['calificacion']),
      commercialStatus: _text(json['estado_comercial']),
      stage: _text(json['etapa']),
      type: _text(json['tipo']),
      owner: _text(json['propietario']),
      assignee: _text(json['responsable']),
      createdAt: _text(json['creado']),
      updatedAt: _text(json['actualizado']),
    );
  }

  /// Body of `crear_contacto`. `nombre`, `tipo`, `estado_comercial` and
  /// `etapa` are required by the API.
  Map<String, dynamic> toCreateDatos() {
    return {
      'nombre': firstName,
      'apellidos': lastName,
      'tipo': type,
      'estado_comercial': commercialStatus,
      'etapa': stage,
      ..._profileDatos(),
    };
  }

  /// Body of `actualizar_contacto`. Stage and commercial status have their
  /// own requests (`actualizar_etapa_contacto`, `convertir_contacto`).
  Map<String, dynamic> toUpdateDatos() {
    return {
      'id_contacto': id,
      'nombre': firstName,
      'apellidos': lastName,
      'tipo': type,
      ..._profileDatos(),
    };
  }

  Map<String, dynamic> _profileDatos() {
    return {
      'industria': industry,
      'organizacion': company,
      'cargo': jobTitle,
      'telefono': phone,
      'movil': mobile,
      'email': email,
      'web': web,
      'direccion': address,
      'ciudad': city,
      'estado': state,
      'pais': country,
      'postal': postal,
      'descripcion': description,
      'origen': source,
      'interes': interest,
      'calificacion': qualification,
      'responsable': assignee,
    };
  }
}

String _text(Object? value) => value == null ? '' : value.toString();

String _orDash(String value) => value.trim().isEmpty ? '—' : value;
