/// Datos de perfil específicos del rol PACIENTE (HU-02).
class PerfilPaciente {
  const PerfilPaciente({
    required this.direccion,
    required this.fechaNacimiento,
    required this.fotoCedulaPath,
  });

  final String? direccion;
  final String? fechaNacimiento;
  final String? fotoCedulaPath;

  factory PerfilPaciente.fromJson(Map<String, dynamic> json) {
    return PerfilPaciente(
      direccion: json['direccion'] as String?,
      fechaNacimiento: json['fechaNacimiento'] as String?,
      fotoCedulaPath: json['fotoCedulaPath'] as String?,
    );
  }
}
