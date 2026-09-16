/// Un resultado alterno que Nominatim devolvió para la misma
/// búsqueda — ver `VerificacionDireccion.candidatos`. Mismo concepto
/// que `CandidatoDireccion` en `solicitudes` (no se reusa esa clase a
/// propósito: cada feature tiene su propio modelo de dominio, mismo
/// criterio que separa los módulos del lado de la API).
class CandidatoDireccionPerfil {
  const CandidatoDireccionPerfil({
    required this.lat,
    required this.lng,
    required this.direccionResuelta,
    required this.precisa,
  });

  final double lat;
  final double lng;
  final String direccionResuelta;
  final bool precisa;

  factory CandidatoDireccionPerfil.fromJson(Map<String, dynamic> json) {
    return CandidatoDireccionPerfil(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      direccionResuelta: json['direccionResuelta'] as String,
      precisa: json['precisa'] as bool? ?? true,
    );
  }
}

/// Resultado de geocodificar una dirección del perfil SIN guardarla —
/// ver `VerificarDireccionUseCase` del lado de la API. Ronda 12 — bug
/// real reportado: la dirección del perfil recién se validaba al
/// tocar "Guardar cambios", sin loader ni sugerencias mientras tanto.
class VerificacionDireccion {
  const VerificacionDireccion({
    required this.direccionResuelta,
    required this.precisa,
    required this.candidatos,
  });

  /// `null` si Nominatim no encontró nada (ni siquiera un lugar
  /// impreciso) — la dirección tal cual no es geocodificable.
  final String? direccionResuelta;
  final bool precisa;
  final List<CandidatoDireccionPerfil> candidatos;

  factory VerificacionDireccion.fromJson(Map<String, dynamic> json) {
    final candidatosJson = json['candidatos'];
    return VerificacionDireccion(
      direccionResuelta: json['direccionResuelta'] as String?,
      precisa: json['precisa'] as bool? ?? true,
      candidatos: candidatosJson is List
          ? candidatosJson
              .map((e) => CandidatoDireccionPerfil.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}
