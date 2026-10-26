import 'package:flutter/foundation.dart';

/// Perfil propio. Son los campos de `actualizar_cuenta`.
@immutable
class AccountProfile {
  const AccountProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.role = 'Usuario',
  });

  /// Perfil inicial a partir del correo del login: `ana.cruz@x.com` pasa a
  /// llamarse "Ana Cruz".
  factory AccountProfile.fromEmail(String email) {
    final local = email.split('@').first;
    final words = local
        .split(RegExp(r'[._\-+]+'))
        .where((w) => w.isNotEmpty && !RegExp(r'^\d+$').hasMatch(w))
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .toList();
    return AccountProfile(
      firstName: words.isEmpty ? 'Usuario' : words.first,
      lastName: words.skip(1).join(' '),
      email: email,
      phone: '',
    );
  }

  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  /// Solo se muestra: el login de la API aún no devuelve el rol.
  final String role;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final parts = [firstName, lastName].where((p) => p.trim().isNotEmpty);
    final value = parts.map((p) => p.trim()[0]).take(2).join().toUpperCase();
    return value.isEmpty ? '?' : value;
  }

  AccountProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) {
    return AccountProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
    );
  }

  Map<String, dynamic> toDatos() {
    return {
      'nombre': firstName,
      'apellidos': lastName,
      'email': email,
      'telefono': phone,
    };
  }
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

/// `null` si [value] parece un correo válido; si no, el mensaje de error.
String? emailError(String value) {
  final text = value.trim();
  if (text.isEmpty) return 'Escribe tu correo.';
  if (!_emailPattern.hasMatch(text)) return 'Ese correo no parece válido.';
  return null;
}
