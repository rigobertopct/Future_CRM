import '../../core/api/crm_client.dart';
import 'opportunity.dart';

abstract class OpportunitiesApi {
  /// Contactos que pueden tener oportunidades.
  Future<List<OpportunityContact>> contacts();

  /// `oportunidades` solo lista las de un contacto.
  Future<List<Opportunity>> forContact(String contactId);

  Future<void> create(OpportunityDraft draft);

  Future<void> update(Opportunity opportunity);

  /// `actualizar_etapa_oportunidad` también registra la etapa en el pipeline.
  Future<void> updateStage(String id, OpportunityStage stage, {String note});

  /// Cambios de etapa registrados (`pipelines`).
  Future<List<PipelineEntry>> history(String id);

  Future<void> delete(String id);
}

class HttpOpportunitiesApi implements OpportunitiesApi {
  HttpOpportunitiesApi({CrmClient? client}) : _client = client ?? CrmClient();

  final CrmClient _client;

  @override
  Future<List<OpportunityContact>> contacts() async {
    final envelope = await _client.post('contactos', {'exec': 'ok'});
    return [
      for (final item in _list(envelope.datos))
        if (item['eliminado'] == null) OpportunityContact.fromJson(item),
    ];
  }

  @override
  Future<List<Opportunity>> forContact(String contactId) async {
    final envelope = await _client.post('oportunidades', {
      'id_contacto': contactId,
    });
    return [
      for (final item in _list(envelope.datos)) Opportunity.fromJson(item),
    ];
  }

  @override
  Future<void> create(OpportunityDraft draft) async {
    await _client.post('crear_oportunidad', draft.toDatos());
  }

  @override
  Future<void> update(Opportunity opportunity) async {
    await _client.post('actualizar_oportunidad', opportunity.toUpdateDatos());
  }

  @override
  Future<void> updateStage(
    String id,
    OpportunityStage stage, {
    String note = '',
  }) async {
    await _client.post('actualizar_etapa_oportunidad', {
      'id_oportunidad': id,
      'etapa': stage.raw,
      if (note.trim().isNotEmpty) 'nota': note.trim(),
    });
  }

  @override
  Future<List<PipelineEntry>> history(String id) async {
    final envelope = await _client.post('pipelines', {'id_oportunidad': id});
    return [
      for (final item in _list(envelope.datos)) PipelineEntry.fromJson(item),
    ];
  }

  @override
  Future<void> delete(String id) async {
    await _client.post('eliminar_oportunidad', {'id_oportunidad': id});
  }

  static List<Map<String, dynamic>> _list(Object? datos) {
    if (datos is! List) return const [];
    return [
      for (final item in datos)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }
}
