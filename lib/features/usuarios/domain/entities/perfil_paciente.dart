/// Datos de perfil específicos del rol PACIENTE (HU-02).
class PerfilPaciente {
  const PerfilPaciente({
    required this.direccion,
    required this.fechaNacimiento,
    required this.fotoCedulaUrl,
    required this.departamento,
    required this.ciudad,
  });

  final String? direccion;
  final String? fechaNacimiento;

  /// URL firmada de corta duración (la API nunca expone el path interno
  /// de Storage — DOCS/context.md, Parte B, sección 3).
  final String? fotoCedulaUrl;

  /// HU-09 — contexto de geocodificación (dirección de entrega y de
  /// farmacia de cada pedido). Obligatorios desde acá al guardar.
  final String? departamento;
  final String? ciudad;

  factory PerfilPaciente.fromJson(Map<String, dynamic> json) {
    return PerfilPaciente(
      direccion: json['direccion'] as String?,
      fechaNacimiento: json['fechaNacimiento'] as String?,
      fotoCedulaUrl: json['fotoCedulaUrl'] as String?,
      departamento: json['departamento'] as String?,
      ciudad: json['ciudad'] as String?,
    );
  }
}
