import 'package:flutter/foundation.dart';

import '../../core/api/crm_client.dart';
import 'opportunities_api.dart';
import 'opportunity.dart';

export 'opportunity.dart';

enum OpportunitySort {
  amount('Importe'),
  closeDate('Cierre');

  const OpportunitySort(this.label);

  final String label;
}

/// Pipeline de oportunidades de la API, con filtros, búsqueda y orden.
///
/// La API no tiene una lista global: se piden los contactos y luego
/// `oportunidades` de cada uno, con pocas peticiones a la vez.
class OpportunitiesStore extends ChangeNotifier {
  OpportunitiesStore({OpportunitiesApi? api})
    : _api = api ?? HttpOpportunitiesApi();

  /// Peticiones `oportunidades` simultáneas durante la carga.
  static const int _parallelRequests = 4;

  final OpportunitiesApi _api;
  final List<Opportunity> _items = [];
  final Map<String, OpportunityContact> _contacts = {};

  OpportunityStage? stageFilter;
  OpportunitySort sort = OpportunitySort.amount;
  String _query = '';
  bool _loading = false;
  String? _error;
  int _generation = 0;
  bool _disposed = false;

  String get query => _query;
  bool get loading => _loading;
  String? get error => _error;
  List<Opportunity> get all => List.unmodifiable(_items);
  List<OpportunityContact> get contacts => List.unmodifiable(_contacts.values);

  OpportunityContact? contactOf(Opportunity item) => _contacts[item.contactId];

  List<Opportunity> get visible {
    final q = _query.toLowerCase();
    final list = _items.where((o) {
      if (stageFilter != null && o.stage != stageFilter) return false;
      if (q.isEmpty) return true;
      final contact = contactOf(o)?.name ?? '';
      return o.name.toLowerCase().contains(q) ||
          o.company.toLowerCase().contains(q) ||
          o.owner.toLowerCase().contains(q) ||
          contact.toLowerCase().contains(q);
    }).toList();
    list.sort(
      (a, b) => switch (sort) {
        OpportunitySort.amount => b.amount.compareTo(a.amount),
        OpportunitySort.closeDate => _compareDates(a.closeDate, b.closeDate),
      },
    );
    return list;
  }

  int countFor(OpportunityStage? stage) =>
      _items.where((o) => stage == null || o.stage == stage).length;

  double totalFor(OpportunityStage? stage) => _items
      .where((o) => stage == null || o.stage == stage)
      .fold(0, (sum, o) => sum + o.amount);

  double get openValue =>
      _items.where((o) => o.stage.isOpen).fold(0, (sum, o) => sum + o.amount);

  double get weightedValue =>
      _items.where((o) => o.stage.isOpen).fold(0, (sum, o) => sum + o.weighted);

  double get wonValue => totalFor(OpportunityStage.won);

  void setStageFilter(OpportunityStage? value) {
    if (stageFilter == value) return;
    stageFilter = value;
    notifyListeners();
  }

  void setSort(OpportunitySort value) {
    if (sort == value) return;
    sort = value;
    notifyListeners();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  /// Recarga contactos y oportunidades. Una carga nueva descarta la anterior.
  Future<void> refresh() async {
    final generation = ++_generation;
    _loading = true;
    _error = null;
    _notify();
    try {
      final contacts = await _api.contacts();
      if (generation != _generation) return;

      final loaded = <Opportunity>[];
      var failures = 0;
      for (var i = 0; i < contacts.length; i += _parallelRequests) {
        final batch = contacts.skip(i).take(_parallelRequests);
        final results = await Future.wait(
          batch.map((contact) async {
            try {
              return await _api.forContact(contact.id);
            } on Object {
              failures++;
              return const <Opportunity>[];
            }
          }),
        );
        if (generation != _generation) return;
        for (final list in results) {
          loaded.addAll(list);
        }
      }

      _contacts
        ..clear()
        ..addEntries(contacts.map((c) => MapEntry(c.id, c)));
      _items
        ..clear()
        ..addAll(loaded);
      if (failures > 0) {
        _error = failures == contacts.length
            ? 'No se pudieron cargar las oportunidades'
            : 'Algunas oportunidades no se pudieron cargar';
      }
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

  /// Cambia la etapa al momento y la deshace si la API la rechaza.
  /// [note] queda en el historial. Devuelve el mensaje de error, o `null`.
  Future<String?> setStage(
    String id,
    OpportunityStage stage, {
    String note = '',
  }) async {
    final index = _items.indexWhere((o) => o.id == id);
    if (index < 0) return 'No se encontró la oportunidad';
    final previous = _items[index];
    if (previous.stage == stage) return null;

    _items[index] = previous.copyWith(stage: stage);
    _notify();
    try {
      await _api.updateStage(id, stage, note: note);
      return null;
    } catch (error) {
      final current = _items.indexWhere((o) => o.id == id);
      if (current >= 0) _items[current] = previous;
      _notify();
      return _message(error);
    }
  }

  /// Mueve la oportunidad a la siguiente etapa. Devuelve `null` si ya estaba
  /// cerrada o no existe.
  Future<String?>? advance(String id) {
    final index = _items.indexWhere((o) => o.id == id);
    final next = index < 0 ? null : _items[index].stage.next;
    if (next == null) return null;
    return setStage(id, next);
  }

  /// Crea la oportunidad y recarga solo las de su contacto.
  Future<String?> add(OpportunityDraft draft) async {
    try {
      await _api.create(draft);
      final fresh = await _api.forContact(draft.contactId);
      _items
        ..removeWhere((o) => o.contactId == draft.contactId)
        ..addAll(fresh);
      _notify();
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  /// Guarda los cambios y recarga las oportunidades de su contacto.
  Future<String?> edit(Opportunity updated) async {
    try {
      await _api.update(updated);
      final fresh = await _api.forContact(updated.contactId);
      _items
        ..removeWhere((o) => o.contactId == updated.contactId)
        ..addAll(fresh);
      _notify();
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  /// Historial de etapas, del más reciente al más antiguo. Lanza
  /// [CrmApiException] para que la vista muestre el error.
  Future<List<PipelineEntry>> history(String id) async {
    try {
      final entries = await _api.history(id);
      entries.sort((a, b) {
        if (a.at == null || b.at == null) return 0;
        return b.at!.compareTo(a.at!);
      });
      return entries;
    } on CrmApiException {
      rethrow;
    } catch (error) {
      throw CrmApiException(_message(error), cause: error);
    }
  }

  Future<String?> remove(String id) async {
    try {
      await _api.delete(id);
      _items.removeWhere((o) => o.id == id);
      _notify();
      return null;
    } catch (error) {
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
