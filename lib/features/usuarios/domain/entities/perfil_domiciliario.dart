/// Datos de perfil específicos del rol DOMICILIARIO (HU-02) — incluye
/// los documentos de validación que HU-08 revisará después.
class PerfilDomiciliario {
  const PerfilDomiciliario({
    required this.direccion,
    required this.vehiculoTipo,
    required this.vehiculoPlaca,
    required this.cedulaPath,
    required this.licenciaPath,
    required this.soatPath,
    required this.tecnicomecanicaPath,
  });

  final String? direccion;
  final String? vehiculoTipo;
  final String? vehiculoPlaca;
  final String? cedulaPath;
  final String? licenciaPath;
  final String? soatPath;
  final String? tecnicomecanicaPath;

  factory PerfilDomiciliario.fromJson(Map<String, dynamic> json) {
    return PerfilDomiciliario(
      direccion: json['direccion'] as String?,
      vehiculoTipo: json['vehiculoTipo'] as String?,
      vehiculoPlaca: json['vehiculoPlaca'] as String?,
      cedulaPath: json['cedulaPath'] as String?,
      licenciaPath: json['licenciaPath'] as String?,
      soatPath: json['soatPath'] as String?,
      tecnicomecanicaPath: json['tecnicomecanicaPath'] as String?,
    );
  }
}
