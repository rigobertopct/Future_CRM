import '../../core/api/crm_client.dart';
import 'account.dart';

/// Acciones sobre el perfil propio (sección "Cuenta" del API).
abstract class AccountApi {
  Future<void> update(AccountProfile profile);

  Future<void> delete();
}

class HttpAccountApi implements AccountApi {
  HttpAccountApi({CrmClient? client}) : _client = client ?? CrmClient();

  final CrmClient _client;

  @override
  Future<void> update(AccountProfile profile) async {
    await _client.post('actualizar_cuenta', profile.toDatos());
  }

  @override
  Future<void> delete() async {
    await _client.post('eliminar_cuenta', const {});
  }
}
