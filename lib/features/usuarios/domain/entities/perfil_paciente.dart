/// Datos de perfil específicos del rol PACIENTE (HU-02).
class PerfilPaciente {
  const PerfilPaciente({
    required this.direccion,
    required this.fechaNacimiento,
    required this.fotoCedulaFrenteUrl,
    required this.fotoCedulaReversoUrl,
    required this.departamento,
    required this.ciudad,
  });

  final String? direccion;
  final String? fechaNacimiento;

  /// URLs firmadas de corta duración (la API nunca expone el path
  /// interno de Storage — DOCS/context.md, Parte B, sección 3). La
  /// cédula colombiana trae información necesaria en las dos caras,
  /// así que se pide y se muestra frente y reverso por separado.
  final String? fotoCedulaFrenteUrl;
  final String? fotoCedulaReversoUrl;

  /// HU-09 — contexto de geocodificación (dirección de entrega y de
  /// farmacia de cada pedido). Obligatorios desde acá al guardar.
  final String? departamento;
  final String? ciudad;

  factory PerfilPaciente.fromJson(Map<String, dynamic> json) {
    return PerfilPaciente(
      direccion: json['direccion'] as String?,
      fechaNacimiento: json['fechaNacimiento'] as String?,
      fotoCedulaFrenteUrl: json['fotoCedulaFrenteUrl'] as String?,
      fotoCedulaReversoUrl: json['fotoCedulaReversoUrl'] as String?,
      departamento: json['departamento'] as String?,
      ciudad: json['ciudad'] as String?,
    );
  }
}
