import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'crm_session.dart';

class CrmApiException implements Exception {
  CrmApiException(this.message, {this.cause});

  final String message;

  /// Underlying error, kept so failures can be diagnosed while the UI shows
  /// only [message].
  final Object? cause;

  @override
  String toString() => message;
}

class CrmEnvelope {
  const CrmEnvelope(this.message, this.datos);

  final String message;
  final Object? datos;
}

class CrmClient {
  CrmClient({http.Client? client, String? endpoint, String? token})
    : _client = client ?? http.Client(),
      endpoint = endpoint ?? CrmSession.endpoint,
      token = token ?? CrmSession.token;

  final http.Client _client;
  final String endpoint;
  final String token;

  Future<CrmEnvelope> post(String request, Map<String, dynamic> datos) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'token': token,
              'request': request,
              'datos': datos,
            }),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException catch (error) {
      throw CrmApiException(
        'El servidor tardó demasiado en responder',
        cause: error,
      );
    } catch (error) {
      throw CrmApiException(
        'No se pudo conectar con el servidor',
        cause: error,
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw CrmApiException(
        'El servidor envió una respuesta inválida',
        cause: error,
      );
    }
    if (decoded is! Map) {
      throw CrmApiException('El servidor envió una respuesta inválida');
    }
    final body = Map<String, dynamic>.from(decoded);
    final message = body['mensaje']?.toString() ?? '';
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['ok'] != true) {
      throw CrmApiException(message.isEmpty ? 'La solicitud falló' : message);
    }
    return CrmEnvelope(message, body['datos']);
  }
}
