import 'package:flutter/foundation.dart';

import '../../core/api/crm_client.dart';
import 'account.dart';
import 'account_api.dart';
import 'auth_api.dart';

/// Sesión de la app.
///
/// [signIn] llama a `acceso` y guarda el token en [client], el cliente que
/// comparten todas las peticiones del CRM. El token vive solo en memoria:
/// al cerrar la app hay que volver a entrar.
class SessionStore extends ChangeNotifier {
  SessionStore({
    CrmClient? client,
    AccountApi? api,
    AuthApi? auth,
    AccountProfile? profile,
  }) : this._withClient(client ?? CrmClient(), api, auth, profile);

  SessionStore._withClient(
    this.client,
    AccountApi? api,
    AuthApi? auth,
    this._profile,
  ) : _api = api ?? HttpAccountApi(client: client),
      _auth = auth ?? HttpAuthApi(client: client);

  static const int minPasswordLength = 3;

  /// Cliente autenticado con el token de la sesión.
  final CrmClient client;

  final AccountApi _api;
  final AuthApi _auth;

  AccountProfile? _profile;
  bool _busy = false;

  AccountProfile? get profile => _profile;
  bool get signedIn => _profile != null;
  bool get busy => _busy;

  /// Devuelve el mensaje de error, o `null` si entró.
  Future<String?> signIn(String email, String password) async {
    if (_busy) return null;
    final invalidEmail = emailError(email);
    if (invalidEmail != null) return invalidEmail;
    if (password.length < minPasswordLength) {
      return 'La contraseña debe tener al menos $minPasswordLength caracteres.';
    }
    final normalized = email.trim().toLowerCase();
    return _run(() async {
      client.token = await _auth.signIn(normalized, password);
      _profile = AccountProfile.fromEmail(normalized);
    });
  }

  void signOut() {
    if (_profile == null) return;
    client.token = null;
    _profile = null;
    notifyListeners();
  }

  /// Guarda el perfil con `actualizar_cuenta`.
  Future<String?> updateProfile(AccountProfile profile) {
    return _run(() async {
      await _api.update(profile);
      _profile = profile;
    });
  }

  /// Borra la cuenta con `eliminar_cuenta` y cierra la sesión.
  Future<String?> deleteAccount() {
    return _run(() async {
      await _api.delete();
      client.token = null;
      _profile = null;
    });
  }

  Future<String?> _run(Future<void> Function() action) async {
    if (_busy) return 'Espera a que termine la operación anterior.';
    _busy = true;
    notifyListeners();
    try {
      await action();
      return null;
    } on CrmApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'No se pudo conectar con el servidor';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
