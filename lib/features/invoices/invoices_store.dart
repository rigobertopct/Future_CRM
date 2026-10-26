import 'package:flutter/foundation.dart';

enum InvoiceStatus {
  paid('Pagada'),
  pending('Pendiente'),
  overdue('Vencida');

  const InvoiceStatus(this.label);

  final String label;
}

@immutable
class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.client,
    required this.amount,
    required this.issued,
    required this.due,
    required this.status,
    this.reminders = 0,
  });

  final String id;
  final String number;
  final String client;
  final double amount;
  final DateTime issued;
  final DateTime due;
  final InvoiceStatus status;

  /// Recordatorios de pago enviados.
  final int reminders;

  Invoice copyWith({InvoiceStatus? status, int? reminders}) => Invoice(
    id: id,
    number: number,
    client: client,
    amount: amount,
    issued: issued,
    due: due,
    status: status ?? this.status,
    reminders: reminders ?? this.reminders,
  );
}

class InvoicesStore extends ChangeNotifier {
  InvoicesStore({DateTime? now, List<Invoice>? seed})
    : _now = now ?? DateTime.now() {
    _items = List.of(seed ?? _sample(_now));
    _nextNumber = 2050 + _items.length;
  }

  final DateTime _now;
  late List<Invoice> _items;
  late int _nextNumber;

  InvoiceStatus? statusFilter;
  String _query = '';

  String get query => _query;
  List<Invoice> get all => List.unmodifiable(_items);

  List<Invoice> get visible {
    final q = _query.toLowerCase();
    final list = _items.where((i) {
      if (statusFilter != null && i.status != statusFilter) return false;
      if (q.isEmpty) return true;
      return i.client.toLowerCase().contains(q) ||
          i.number.toLowerCase().contains(q);
    }).toList();
    list.sort((a, b) => b.due.compareTo(a.due));
    return list;
  }

  int countFor(InvoiceStatus? status) =>
      _items.where((i) => status == null || i.status == status).length;

  double totalFor(InvoiceStatus status) => _items
      .where((i) => i.status == status)
      .fold(0, (sum, i) => sum + i.amount);

  void setStatusFilter(InvoiceStatus? value) {
    if (statusFilter == value) return;
    statusFilter = value;
    notifyListeners();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void markPaid(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index < 0 || _items[index].status == InvoiceStatus.paid) return;
    _items[index] = _items[index].copyWith(status: InvoiceStatus.paid);
    notifyListeners();
  }

  /// Registra un recordatorio. Solo aplica a facturas por cobrar.
  bool remind(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index < 0 || _items[index].status == InvoiceStatus.paid) return false;
    _items[index] = _items[index].copyWith(
      reminders: _items[index].reminders + 1,
    );
    notifyListeners();
    return true;
  }

  Invoice add({required String client, required double amount}) {
    final created = Invoice(
      id: 'in-$_nextNumber',
      number: 'F-${_nextNumber++}',
      client: client,
      amount: amount,
      issued: _now,
      due: _now.add(const Duration(days: 30)),
      status: InvoiceStatus.pending,
    );
    _items.insert(0, created);
    notifyListeners();
    return created;
  }

  static List<Invoice> _sample(DateTime now) {
    Invoice inv(
      int n,
      String client,
      double amount,
      int issuedDaysAgo,
      int dueInDays,
      InvoiceStatus status, {
      int reminders = 0,
    }) => Invoice(
      id: 'in-$n',
      number: 'F-$n',
      client: client,
      amount: amount,
      issued: now.subtract(Duration(days: issuedDaysAgo)),
      due: now.add(Duration(days: dueInDays)),
      status: status,
      reminders: reminders,
    );
    const paid = InvoiceStatus.paid;
    const pending = InvoiceStatus.pending;
    const overdue = InvoiceStatus.overdue;
    return [
      inv(2041, 'Lumen Salud', 2200, 48, -18, overdue, reminders: 2),
      inv(2042, 'Brisa Hoteles', 4700, 40, -10, overdue, reminders: 1),
      inv(2043, 'Veltrix Logística', 12900, 22, 8, pending),
      inv(2044, 'Grupo Aurelia', 18400, 30, 0, pending),
      inv(2045, 'Nexora Labs', 15200, 12, 18, pending),
      inv(2046, 'Solaris Energía', 9800, 55, -25, paid),
      inv(2047, 'Kairos Retail', 6400, 45, -15, paid),
      inv(2048, 'Altamar Foods', 7200, 38, -8, paid),
      inv(2049, 'Orbita Fintech', 2900, 33, -3, paid),
      inv(2050, 'Montalvo & Asoc.', 3900, 18, 12, pending),
      inv(2051, 'Pixel Studio', 1500, 62, -32, paid),
      inv(2052, 'Zenit Motors', 1800, 70, -40, overdue, reminders: 3),
    ];
  }
}
