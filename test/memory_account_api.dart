import 'package:future_crm/core/api/crm_client.dart';
import 'package:future_crm/features/auth/account.dart';
import 'package:future_crm/features/auth/account_api.dart';
import 'package:future_crm/features/auth/session_store.dart';

class MemoryAccountApi implements AccountApi {
  MemoryAccountApi({this.fail = false});

  final bool fail;
  final List<String> calls = [];

  @override
  Future<void> update(AccountProfile profile) async {
    calls.add('actualizar_cuenta');
    if (fail) throw CrmApiException('No se pudo guardar');
  }

  @override
  Future<void> delete() async {
    calls.add('eliminar_cuenta');
    if (fail) throw CrmApiException('No se pudo eliminar');
  }
}

const testProfile = AccountProfile(
  firstName: 'Marta',
  lastName: 'Ibáñez',
  email: 'marta@example.com',
  phone: '',
);

/// Sesión ya iniciada para los tests que abren la app directamente.
SessionStore signedInSession({AccountApi? api, bool demo = false}) {
  return SessionStore(
    api: api ?? MemoryAccountApi(),
    profile: testProfile,
    demo: demo,
    signInDelay: Duration.zero,
  );
}
