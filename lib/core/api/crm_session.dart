/// Configuración del API del CRM.
///
/// Los valores vienen de `--dart-define`:
/// `flutter run --dart-define=CRM_ENDPOINT=... --dart-define=CRM_OWNER=...`.
/// El token ya no es fijo: lo devuelve `acceso` al iniciar sesión.
abstract final class CrmSession {
  static const endpoint = String.fromEnvironment(
    'CRM_ENDPOINT',
    defaultValue: 'https://api.qainos.com/',
  );
  static const owner = String.fromEnvironment('CRM_OWNER', defaultValue: '123');
}
