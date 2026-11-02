import '../../core/api/crm_client.dart';

/// Inicio de sesión (sección "Login / Registro" del API).
abstract class AuthApi {
  /// Devuelve el token de la sesión.
  Future<String> signIn(String email, String password);
}

class HttpAuthApi implements AuthApi {
  HttpAuthApi({required this._client});

  final CrmClient _client;

  @override
  Future<String> signIn(String email, String password) async {
    final envelope = await _client.post('acceso', {
      'email': email,
      'clave': password,
    }, authenticated: false);
    final datos = envelope.datos;
    final token = datos is Map ? datos['token'] : null;
    if (token is! String || token.isEmpty) {
      throw CrmApiException('El servidor no devolvió la sesión');
    }
    return token;
  }
}
