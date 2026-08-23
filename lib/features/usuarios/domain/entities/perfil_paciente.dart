/// Datos de perfil específicos del rol PACIENTE (HU-02).
class PerfilPaciente {
  const PerfilPaciente({
    required this.direccion,
    required this.fechaNacimiento,
    required this.fotoCedulaUrl,
  });

  final String? direccion;
  final String? fechaNacimiento;

  /// URL firmada de corta duración (la API nunca expone el path interno
  /// de Storage — DOCS/context.md, Parte B, sección 3).
  final String? fotoCedulaUrl;

  factory PerfilPaciente.fromJson(Map<String, dynamic> json) {
    return PerfilPaciente(
      direccion: json['direccion'] as String?,
      fechaNacimiento: json['fechaNacimiento'] as String?,
      fotoCedulaUrl: json['fotoCedulaUrl'] as String?,
    );
  }
}
