import 'package:flutter/foundation.dart';

import '../../core/api/crm_client.dart';
import 'account.dart';
import 'account_api.dart';

/// Sesión de la app.
///
/// El login es **ficticio** mientras el API no documente `login`: acepta
/// cualquier correo válido con una contraseña de 3 o más caracteres y usa el
/// token configurado en `CrmSession`. Cuando exista el endpoint, solo cambia
/// [signIn].
class SessionStore extends ChangeNotifier {
  SessionStore({
    AccountApi? api,
    this.signInDelay = const Duration(milliseconds: 1100),
    this._profile,
    this._demo = false,
  }) : _api = api ?? HttpAccountApi();

  static const int minPasswordLength = 3;

  final AccountApi _api;

  /// Espera simulada del login, para que se vea el estado de carga.
  final Duration signInDelay;

  AccountProfile? _profile;
  bool _busy = false;
  bool _demo;

  AccountProfile? get profile => _profile;

  /// Sesión del login ficticio: comparte el token de pruebas, así que no se
  /// debe borrar la cuenta desde ella.
  bool get demo => _demo;
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
    _busy = true;
    notifyListeners();
    await Future<void>.delayed(signInDelay);
    _busy = false;
    _profile = AccountProfile.fromEmail(email.trim().toLowerCase());
    _demo = true;
    notifyListeners();
    return null;
  }

  void signOut() {
    if (_profile == null) return;
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
    if (_demo) {
      return Future.value(
        'No disponible en la sesión de demostración: borraría la cuenta '
        'de pruebas compartida.',
      );
    }
    return _run(() async {
      await _api.delete();
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
