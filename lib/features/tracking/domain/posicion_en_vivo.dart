/// Respuesta de `tracking:posicion_inicial` — el "mapa completo" al
/// abrir la pantalla: dónde está el domiciliario (si ya mandó algo),
/// la farmacia y el destino de entrega, fijos.
class PosicionEnVivo {
  const PosicionEnVivo({
    required this.estado,
    required this.domiciliarioLat,
    required this.domiciliarioLng,
    required this.ubicacionActualizadaEn,
    required this.farmaciaLat,
    required this.farmaciaLng,
    required this.entregaLat,
    required this.entregaLng,
  });

  final String estado;
  final double? domiciliarioLat;
  final double? domiciliarioLng;
  final DateTime? ubicacionActualizadaEn;
  final double? farmaciaLat;
  final double? farmaciaLng;
  final double? entregaLat;
  final double? entregaLng;

  factory PosicionEnVivo.fromJson(Map<String, dynamic> json) {
    return PosicionEnVivo(
      estado: json['estado'] as String,
      domiciliarioLat: (json['domiciliarioLat'] as num?)?.toDouble(),
      domiciliarioLng: (json['domiciliarioLng'] as num?)?.toDouble(),
      ubicacionActualizadaEn: json['ubicacionActualizadaEn'] == null
          ? null
          : DateTime.parse(json['ubicacionActualizadaEn'] as String).toLocal(),
      farmaciaLat: (json['farmaciaLat'] as num?)?.toDouble(),
      farmaciaLng: (json['farmaciaLng'] as num?)?.toDouble(),
      entregaLat: (json['entregaLat'] as num?)?.toDouble(),
      entregaLng: (json['entregaLng'] as num?)?.toDouble(),
    );
  }
}

/// Evento `tracking:posicion` — un ping nuevo del domiciliario.
class PosicionActualizada {
  const PosicionActualizada({required this.lat, required this.lng, required this.actualizadoEn});

  final double lat;
  final double lng;
  final DateTime actualizadoEn;

  factory PosicionActualizada.fromJson(Map<String, dynamic> json) {
    return PosicionActualizada(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String).toLocal(),
    );
  }
}
