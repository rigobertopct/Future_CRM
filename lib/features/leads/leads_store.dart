import 'package:flutter/foundation.dart';

import '../../core/api/crm_client.dart';
import '../../core/api/crm_session.dart';
import 'lead.dart';
import 'leads_api.dart';

class LeadsStore extends ChangeNotifier {
  LeadsStore({LeadsApi? api, String? owner})
    : _api = api ?? HttpLeadsApi(),
      owner = owner ?? CrmSession.owner;

  static const int pageSize = 10;

  final LeadsApi _api;
  final String owner;
  final List<Lead> _leads = [];

  LeadStage? _stageFilter;
  String _query = '';
  int _page = 0;
  bool _loading = true;
  String? _error;

  LeadStage? get stageFilter => _stageFilter;
  String get query => _query;
  int get page => _page;
  bool get loading => _loading;
  String? get error => _error;

  int get total => _leads.length;

  int countFor(LeadStage? stage) {
    if (stage == null) return _leads.length;
    return _leads.where((lead) => lead.stageValue == stage).length;
  }

  List<Lead> get filtered {
    final needle = _query.trim().toLowerCase();
    return [
      for (final lead in _leads)
        if (_matchesStage(lead) && _matchesQuery(lead, needle)) lead,
    ];
  }

  int get pageCount {
    final count = filtered.length;
    if (count == 0) return 1;
    return (count / pageSize).ceil();
  }

  List<Lead> get pageItems {
    final items = filtered;
    final start = _page * pageSize;
    if (start >= items.length) return const [];
    final end = (start + pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _reload();
    } catch (error) {
      _error = _message(error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Lead?> fetchContact(String id) async {
    try {
      final fresh = await _api.contact(id);
      final index = _leads.indexWhere((lead) => lead.id == id);
      if (index != -1) _leads[index] = fresh;
      _error = null;
      notifyListeners();
      return fresh;
    } catch (error) {
      _error = _message(error);
      notifyListeners();
      return null;
    }
  }

  void setStageFilter(LeadStage? stage) {
    _stageFilter = stage;
    _page = 0;
    notifyListeners();
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    _page = 0;
    notifyListeners();
  }

  void setPage(int value) {
    final next = value.clamp(0, pageCount - 1);
    if (next == _page) return;
    _page = next;
    notifyListeners();
  }

  Future<String?> add(Lead lead) {
    final ownerValue = lead.owner.trim().isEmpty ? owner : lead.owner;
    return _mutate(() async {
      await _api.create(lead.copyWith(owner: ownerValue));
      _stageFilter = null;
      _page = 0;
      await _reload();
    });
  }

  Future<String?> update(Lead lead) {
    return _mutate(() async {
      await _api.update(lead);
      await _reload();
    });
  }

  Future<String?> remove(String id) {
    return _mutate(() async {
      await _api.delete(id);
      await _reload();
    });
  }

  Future<String?> changeStage(String id, LeadStage stage) {
    if (_find(id) == null) return Future.value('No se encontró el lead');
    return _mutate(() async {
      await _api.updateStage(id, stage.raw);
      await _reload();
    });
  }

  /// `convertir_contacto` only sends the commercial status.
  Future<String?> convertToClient(String id) {
    return _mutate(() async {
      await _api.convert(id, CommercialStatus.client.raw);
      await _reload();
    });
  }

  Lead? _find(String id) {
    for (final lead in _leads) {
      if (lead.id == id) return lead;
    }
    return null;
  }

  Future<void> _reload() async {
    final items = await _api.listContacts(owner);
    // `contactos` returns every commercial status; prospects and clients
    // have their own stages and do not belong in the leads pipeline.
    _leads
      ..clear()
      ..addAll(
        items.where((lead) => lead.statusValue == CommercialStatus.lead),
      );
    if (_page > pageCount - 1) _page = pageCount - 1;
  }

  Future<String?> _mutate(Future<void> Function() action) async {
    try {
      await action();
      _error = null;
      notifyListeners();
      return null;
    } catch (error) {
      final message = _message(error);
      _error = message;
      notifyListeners();
      return message;
    }
  }

  String _message(Object error) {
    if (error is CrmApiException) return error.message;
    return 'No se pudo conectar con el servidor';
  }

  bool _matchesStage(Lead lead) {
    return stageFilter == null || lead.stageValue == stageFilter;
  }

  bool _matchesQuery(Lead lead, String needle) {
    if (needle.isEmpty) return true;
    final haystack = [
      lead.fullName,
      lead.company,
      lead.email,
      lead.jobTitle,
      lead.description,
      lead.phone,
      lead.mobile,
      lead.city,
    ].join(' ').toLowerCase();
    return haystack.contains(needle);
  }
}

String timestampNow() {
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)} '
      '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
}

String newLeadId() => DateTime.now().microsecondsSinceEpoch.toRadixString(16);
