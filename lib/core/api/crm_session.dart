/// Session used by the CRM API until the backend exposes a login request.
///
/// Values come from `--dart-define` so credentials are not hard-coded:
/// `flutter run --dart-define=CRM_TOKEN=... --dart-define=CRM_OWNER=...`.
/// The defaults are the test session from the API spec ("API CRM" v1.5).
abstract final class CrmSession {
  static const endpoint = String.fromEnvironment(
    'CRM_ENDPOINT',
    defaultValue: 'https://api.qainos.com/',
  );
  static const token = String.fromEnvironment('CRM_TOKEN', defaultValue: '123');
  static const owner = String.fromEnvironment('CRM_OWNER', defaultValue: '123');
}
