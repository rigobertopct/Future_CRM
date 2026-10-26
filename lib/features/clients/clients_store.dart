import 'package:flutter/foundation.dart';

enum ClientSegment {
  enterprise('Enterprise'),
  smb('PyME'),
  startup('Startup');

  const ClientSegment(this.label);

  final String label;
}

enum ClientStatus {
  active('Activo'),
  atRisk('En riesgo'),
  inactive('Inactivo');

  const ClientStatus(this.label);

  final String label;
}

enum ClientSort {
  name('Nombre'),
  mrr('Ingreso'),
  health('Salud');

  const ClientSort(this.label);

  final String label;
}

/// Filtro de la lista: todos, un segmento o solo favoritos.
sealed class ClientFilter {
  const ClientFilter();
}

class AllClients extends ClientFilter {
  const AllClients();

  @override
  bool operator ==(Object other) => other is AllClients;

  @override
  int get hashCode => 0;
}

class FavoriteClients extends ClientFilter {
  const FavoriteClients();

  @override
  bool operator ==(Object other) => other is FavoriteClients;

  @override
  int get hashCode => 1;
}

class SegmentClients extends ClientFilter {
  const SegmentClients(this.segment);

  final ClientSegment segment;

  @override
  bool operator ==(Object other) =>
      other is SegmentClients && other.segment == segment;

  @override
  int get hashCode => segment.hashCode;
}

@immutable
class Client {
  const Client({
    required this.id,
    required this.name,
    required this.industry,
    required this.segment,
    required this.status,
    required this.mrr,
    required this.health,
    required this.contact,
    required this.email,
    required this.city,
    this.favorite = false,
  });

  final String id;
  final String name;
  final String industry;
  final ClientSegment segment;
  final ClientStatus status;

  /// Ingreso mensual recurrente.
  final double mrr;

  /// Salud de la cuenta, de 0 a 100.
  final int health;
  final String contact;
  final String email;
  final String city;
  final bool favorite;

  String get initials {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    final first = parts.first[0];
    return (parts.length > 1 ? first + parts[1][0] : first).toUpperCase();
  }

  Client copyWith({bool? favorite, ClientStatus? status}) => Client(
    id: id,
    name: name,
    industry: industry,
    segment: segment,
    status: status ?? this.status,
    mrr: mrr,
    health: health,
    contact: contact,
    email: email,
    city: city,
    favorite: favorite ?? this.favorite,
  );
}

class ClientsStore extends ChangeNotifier {
  ClientsStore({List<Client>? seed}) {
    _items = List.of(seed ?? _sample);
    _nextId = _items.length + 1;
  }

  late List<Client> _items;
  late int _nextId;

  ClientFilter filter = const AllClients();
  ClientSort sort = ClientSort.mrr;
  String _query = '';

  String get query => _query;
  List<Client> get all => List.unmodifiable(_items);

  bool _matches(Client c, ClientFilter f) => switch (f) {
    AllClients() => true,
    FavoriteClients() => c.favorite,
    SegmentClients(:final segment) => c.segment == segment,
  };

  List<Client> get visible {
    final q = _query.toLowerCase();
    final list = _items.where((c) {
      if (!_matches(c, filter)) return false;
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.industry.toLowerCase().contains(q) ||
          c.contact.toLowerCase().contains(q) ||
          c.city.toLowerCase().contains(q);
    }).toList();
    list.sort(
      (a, b) => switch (sort) {
        ClientSort.name => a.name.compareTo(b.name),
        ClientSort.mrr => b.mrr.compareTo(a.mrr),
        ClientSort.health => b.health.compareTo(a.health),
      },
    );
    return list;
  }

  int countFor(ClientFilter f) => _items.where((c) => _matches(c, f)).length;

  double get totalMrr => _items
      .where((c) => c.status != ClientStatus.inactive)
      .fold(0, (sum, c) => sum + c.mrr);

  int get atRiskCount =>
      _items.where((c) => c.status == ClientStatus.atRisk).length;

  void setFilter(ClientFilter value) {
    if (filter == value) return;
    filter = value;
    notifyListeners();
  }

  void setSort(ClientSort value) {
    if (sort == value) return;
    sort = value;
    notifyListeners();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final index = _items.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(favorite: !_items[index].favorite);
    notifyListeners();
  }

  void setStatus(String id, ClientStatus status) {
    final index = _items.indexWhere((c) => c.id == id);
    if (index < 0 || _items[index].status == status) return;
    _items[index] = _items[index].copyWith(status: status);
    notifyListeners();
  }

  Client add({
    required String name,
    required String industry,
    required ClientSegment segment,
    required String contact,
    required String email,
    required double mrr,
  }) {
    final created = Client(
      id: 'cl-${_nextId++}',
      name: name,
      industry: industry,
      segment: segment,
      status: ClientStatus.active,
      mrr: mrr,
      health: 80,
      contact: contact,
      email: email,
      city: 'Sin definir',
    );
    _items.insert(0, created);
    notifyListeners();
    return created;
  }

  static const _sample = [
    Client(
      id: 'cl-1',
      name: 'Grupo Aurelia',
      industry: 'Retail',
      segment: ClientSegment.enterprise,
      status: ClientStatus.active,
      mrr: 18400,
      health: 92,
      contact: 'Valeria Soto',
      email: 'valeria@aurelia.com',
      city: 'Ciudad de México',
      favorite: true,
    ),
    Client(
      id: 'cl-2',
      name: 'Nexora Labs',
      industry: 'Tecnología',
      segment: ClientSegment.enterprise,
      status: ClientStatus.active,
      mrr: 15200,
      health: 88,
      contact: 'Marcos Ibarra',
      email: 'marcos@nexora.io',
      city: 'Bogotá',
      favorite: true,
    ),
    Client(
      id: 'cl-3',
      name: 'Veltrix Logística',
      industry: 'Logística',
      segment: ClientSegment.enterprise,
      status: ClientStatus.atRisk,
      mrr: 12900,
      health: 54,
      contact: 'Paula Reyes',
      email: 'paula@veltrix.com',
      city: 'Lima',
    ),
    Client(
      id: 'cl-4',
      name: 'Solaris Energía',
      industry: 'Energía',
      segment: ClientSegment.enterprise,
      status: ClientStatus.active,
      mrr: 9800,
      health: 79,
      contact: 'Hugo Navarro',
      email: 'hugo@solaris.es',
      city: 'Madrid',
    ),
    Client(
      id: 'cl-5',
      name: 'Kairos Retail',
      industry: 'Retail',
      segment: ClientSegment.smb,
      status: ClientStatus.active,
      mrr: 6400,
      health: 83,
      contact: 'Lucía Fernández',
      email: 'lucia@kairos.shop',
      city: 'Buenos Aires',
    ),
    Client(
      id: 'cl-6',
      name: 'Brisa Hoteles',
      industry: 'Turismo',
      segment: ClientSegment.smb,
      status: ClientStatus.atRisk,
      mrr: 4700,
      health: 48,
      contact: 'Tomás Cárdenas',
      email: 'tomas@brisa.travel',
      city: 'Cartagena',
    ),
    Client(
      id: 'cl-7',
      name: 'Montalvo & Asoc.',
      industry: 'Servicios legales',
      segment: ClientSegment.smb,
      status: ClientStatus.active,
      mrr: 3900,
      health: 71,
      contact: 'Irene Montalvo',
      email: 'irene@montalvo.law',
      city: 'Santiago',
    ),
    Client(
      id: 'cl-8',
      name: 'Altamar Foods',
      industry: 'Alimentos',
      segment: ClientSegment.smb,
      status: ClientStatus.active,
      mrr: 7200,
      health: 86,
      contact: 'Raúl Peña',
      email: 'raul@altamar.com',
      city: 'Guayaquil',
    ),
    Client(
      id: 'cl-9',
      name: 'Orbita Fintech',
      industry: 'Finanzas',
      segment: ClientSegment.startup,
      status: ClientStatus.active,
      mrr: 2900,
      health: 90,
      contact: 'Daniela Ruiz',
      email: 'daniela@orbita.fi',
      city: 'Montevideo',
      favorite: true,
    ),
    Client(
      id: 'cl-10',
      name: 'Zenit Motors',
      industry: 'Automotriz',
      segment: ClientSegment.startup,
      status: ClientStatus.inactive,
      mrr: 1800,
      health: 31,
      contact: 'Samuel Ortiz',
      email: 'samuel@zenit.mx',
      city: 'Monterrey',
    ),
    Client(
      id: 'cl-11',
      name: 'Lumen Salud',
      industry: 'Salud',
      segment: ClientSegment.startup,
      status: ClientStatus.atRisk,
      mrr: 2200,
      health: 52,
      contact: 'Carolina Vidal',
      email: 'carolina@lumen.health',
      city: 'Quito',
    ),
    Client(
      id: 'cl-12',
      name: 'Pixel Studio',
      industry: 'Medios',
      segment: ClientSegment.startup,
      status: ClientStatus.active,
      mrr: 1500,
      health: 77,
      contact: 'Nicolás Gil',
      email: 'nico@pixel.studio',
      city: 'Medellín',
    ),
  ];
}
