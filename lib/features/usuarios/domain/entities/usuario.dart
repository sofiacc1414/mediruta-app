import 'rol_asignado.dart';

/// Identidad autenticada. No incluye credenciales — `password`/hash nunca
/// salen de la API hacia acá (DOCS/context.md, Parte B, sección 4.1).
class Usuario {
  const Usuario({
    required this.id,
    required this.correo,
    required this.estadoCuenta,
    required this.roles,
  });

  final String id;
  final String correo;
  final String estadoCuenta;
  final List<RolAsignado> roles;

  bool tieneRol(String codigo) => roles.any((r) => r.codigo == codigo);

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      correo: json['correo'] as String,
      estadoCuenta: json['estadoCuenta'] as String,
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((r) => RolAsignado.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
