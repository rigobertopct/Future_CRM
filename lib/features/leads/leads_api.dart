import '../../core/api/crm_client.dart';
import 'lead.dart';

abstract class LeadsApi {
  Future<List<Lead>> listContacts(String owner);

  Future<Lead> contact(String id);

  Future<void> create(Lead lead);

  Future<void> update(Lead lead);

  Future<void> delete(String id);

  Future<void> updateStage(String id, String stage);

  Future<void> convert(String id, String commercialStatus);
}

class HttpLeadsApi implements LeadsApi {
  HttpLeadsApi({CrmClient? client}) : _client = client ?? CrmClient();

  final CrmClient _client;

  @override
  Future<List<Lead>> listContacts(String owner) async {
    final envelope = await _client.post('contactos', {'exec': 'ok'});
    final datos = envelope.datos;
    if (datos is! List) return const [];
    return [
      for (final item in datos)
        if (item is Map && item['eliminado'] == null)
          Lead.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<Lead> contact(String id) async {
    final envelope = await _client.post('contacto', {'id_contacto': id});
    final datos = envelope.datos;
    if (datos is! Map) {
      throw CrmApiException('El contacto no llegó en la respuesta');
    }
    return Lead.fromJson(Map<String, dynamic>.from(datos));
  }

  @override
  Future<void> create(Lead lead) async {
    await _client.post('crear_contacto', lead.toCreateDatos());
  }

  @override
  Future<void> update(Lead lead) async {
    await _client.post('actualizar_contacto', lead.toUpdateDatos());
  }

  @override
  Future<void> delete(String id) async {
    await _client.post('eliminar_contacto', {'id_contacto': id});
  }

  @override
  Future<void> updateStage(String id, String stage) async {
    await _client.post('actualizar_etapa_contacto', {
      'id_contacto': id,
      'etapa': stage,
    });
  }

  @override
  Future<void> convert(String id, String commercialStatus) async {
    await _client.post('convertir_contacto', {
      'id_contacto': id,
      'estado_comercial': commercialStatus,
    });
  }
}
