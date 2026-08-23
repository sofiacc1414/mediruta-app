/// Datos de perfil específicos del rol DOMICILIARIO (HU-02) — incluye
/// los documentos de validación que HU-08 revisará después.
class PerfilDomiciliario {
  const PerfilDomiciliario({
    required this.direccion,
    required this.vehiculoTipo,
    required this.vehiculoPlaca,
    required this.cedulaUrl,
    required this.licenciaUrl,
    required this.soatUrl,
    required this.tecnicomecanicaUrl,
  });

  final String? direccion;
  final String? vehiculoTipo;
  final String? vehiculoPlaca;

  /// URLs firmadas de corta duración (la API nunca expone el path interno
  /// de Storage — DOCS/context.md, Parte B, sección 3).
  final String? cedulaUrl;
  final String? licenciaUrl;
  final String? soatUrl;
  final String? tecnicomecanicaUrl;

  factory PerfilDomiciliario.fromJson(Map<String, dynamic> json) {
    return PerfilDomiciliario(
      direccion: json['direccion'] as String?,
      vehiculoTipo: json['vehiculoTipo'] as String?,
      vehiculoPlaca: json['vehiculoPlaca'] as String?,
      cedulaUrl: json['cedulaUrl'] as String?,
      licenciaUrl: json['licenciaUrl'] as String?,
      soatUrl: json['soatUrl'] as String?,
      tecnicomecanicaUrl: json['tecnicomecanicaUrl'] as String?,
    );
  }
}
