import 'package:future_crm/features/leads/lead.dart';
import 'package:future_crm/features/leads/leads_api.dart';

class MemoryLeadsApi implements LeadsApi {
  MemoryLeadsApi(List<Lead> seed) : _leads = List<Lead>.of(seed);

  final List<Lead> _leads;

  @override
  Future<List<Lead>> listContacts(String owner) async => List<Lead>.of(_leads);

  @override
  Future<Lead> contact(String id) async {
    return _leads.firstWhere((lead) => lead.id == id);
  }

  @override
  Future<void> create(Lead lead) async {
    _leads.insert(0, lead);
  }

  @override
  Future<void> update(Lead lead) async {
    final index = _leads.indexWhere((item) => item.id == lead.id);
    if (index != -1) _leads[index] = lead;
  }

  @override
  Future<void> delete(String id) async {
    _leads.removeWhere((lead) => lead.id == id);
  }

  @override
  Future<void> updateStage(String id, String stage) async {
    final index = _leads.indexWhere((lead) => lead.id == id);
    if (index != -1) _leads[index] = _leads[index].copyWith(stage: stage);
  }

  @override
  Future<void> convert(String id, String commercialStatus) async {
    final index = _leads.indexWhere((lead) => lead.id == id);
    if (index == -1) return;
    _leads[index] = _leads[index].copyWith(
      commercialStatus: commercialStatus,
      stage: LeadStage.converted.raw,
    );
  }
}
