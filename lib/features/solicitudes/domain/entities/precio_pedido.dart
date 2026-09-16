/// Un resultado alterno que Nominatim devolvió para la misma búsqueda —
/// ver `direccionFarmaciaCandidatos`/`direccionEntregaCandidatos` en
/// `PrecioPedido`. Ronda 11 — bug real reportado: un Paciente
/// registrado en un municipio (ej. Amagá) puede estar pidiendo desde
/// otro (ej. San Antonio de Prado, ya en Medellín): el primer
/// resultado de Nominatim no siempre es el correcto.
class CandidatoDireccion {
  const CandidatoDireccion({
    required this.lat,
    required this.lng,
    required this.direccionResuelta,
    required this.precisa,
  });

  final double lat;
  final double lng;
  final String direccionResuelta;
  final bool precisa;

  factory CandidatoDireccion.fromJson(Map<String, dynamic> json) {
    return CandidatoDireccion(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      direccionResuelta: json['direccionResuelta'] as String,
      precisa: json['precisa'] as bool? ?? true,
    );
  }
}

/// Ronda 14 — coordenadas ya confirmadas para una dirección exacta,
/// para mandarlas al enviar el pedido y evitar que ese paso tenga que
/// volver a geocodificar el mismo texto (ver `EnviarSolicitudUseCase`
/// del lado de la API). Si el texto actual ya no coincide con
/// `direccionVerificadaPara` (se editó después de confirmar), el
/// servidor ignora esto y geocodifica de nuevo — no hace falta que la
/// App lo controle, alcanza con mandar lo último confirmado.
class VerificacionDireccionPrevia {
  const VerificacionDireccionPrevia({
    required this.direccionVerificadaPara,
    required this.lat,
    required this.lng,
  });

  final String direccionVerificadaPara;
  final double lat;
  final double lng;
}

/// Precio del pedido (copago + domicilio) — ver `CalcularPrecioPedidoUseCase`
/// del lado de la API. `disponible: false` cuando el Paciente todavía no
/// eligió su nivel de copago, o falta geocodificar la farmacia y/o la
/// entrega (Nominatim no las resolvió, o el pedido todavía no se envió).
class PrecioPedido {
  const PrecioPedido._({
    required this.disponible,
    this.copago,
    this.domicilio,
    this.total,
    this.distanciaKm,
    this.motivo,
    this.direccionFarmaciaResuelta,
    this.direccionFarmaciaPrecisa = true,
    this.direccionFarmaciaCandidatos = const [],
    this.direccionFarmaciaLat,
    this.direccionFarmaciaLng,
    this.direccionEntregaResuelta,
    this.direccionEntregaPrecisa = true,
    this.direccionEntregaCandidatos = const [],
    this.direccionEntregaLat,
    this.direccionEntregaLng,
  });

  factory PrecioPedido.disponible({
    required num copago,
    required num domicilio,
    required num total,
    required num distanciaKm,
    String? direccionFarmaciaResuelta,
    bool direccionFarmaciaPrecisa = true,
    List<CandidatoDireccion> direccionFarmaciaCandidatos = const [],
    double? direccionFarmaciaLat,
    double? direccionFarmaciaLng,
    String? direccionEntregaResuelta,
    bool direccionEntregaPrecisa = true,
    List<CandidatoDireccion> direccionEntregaCandidatos = const [],
    double? direccionEntregaLat,
    double? direccionEntregaLng,
  }) {
    return PrecioPedido._(
      disponible: true,
      copago: copago,
      domicilio: domicilio,
      total: total,
      distanciaKm: distanciaKm,
      direccionFarmaciaResuelta: direccionFarmaciaResuelta,
      direccionFarmaciaPrecisa: direccionFarmaciaPrecisa,
      direccionFarmaciaCandidatos: direccionFarmaciaCandidatos,
      direccionFarmaciaLat: direccionFarmaciaLat,
      direccionFarmaciaLng: direccionFarmaciaLng,
      direccionEntregaResuelta: direccionEntregaResuelta,
      direccionEntregaPrecisa: direccionEntregaPrecisa,
      direccionEntregaCandidatos: direccionEntregaCandidatos,
      direccionEntregaLat: direccionEntregaLat,
      direccionEntregaLng: direccionEntregaLng,
    );
  }

  factory PrecioPedido.noDisponible(
    String motivo, {
    String? direccionFarmaciaResuelta,
    bool direccionFarmaciaPrecisa = true,
    List<CandidatoDireccion> direccionFarmaciaCandidatos = const [],
    double? direccionFarmaciaLat,
    double? direccionFarmaciaLng,
    String? direccionEntregaResuelta,
    bool direccionEntregaPrecisa = true,
    List<CandidatoDireccion> direccionEntregaCandidatos = const [],
    double? direccionEntregaLat,
    double? direccionEntregaLng,
  }) {
    return PrecioPedido._(
      disponible: false,
      motivo: motivo,
      direccionFarmaciaResuelta: direccionFarmaciaResuelta,
      direccionFarmaciaPrecisa: direccionFarmaciaPrecisa,
      direccionFarmaciaCandidatos: direccionFarmaciaCandidatos,
      direccionFarmaciaLat: direccionFarmaciaLat,
      direccionFarmaciaLng: direccionFarmaciaLng,
      direccionEntregaResuelta: direccionEntregaResuelta,
      direccionEntregaPrecisa: direccionEntregaPrecisa,
      direccionEntregaCandidatos: direccionEntregaCandidatos,
      direccionEntregaLat: direccionEntregaLat,
      direccionEntregaLng: direccionEntregaLng,
    );
  }

  final bool disponible;
  final num? copago;
  final num? domicilio;
  final num? total;
  final num? distanciaKm;

  /// 'sin_nivel_copago' | 'sin_ubicaciones' — solo si `!disponible`.
  final String? motivo;

  /// La dirección tal como Nominatim la entendió — para mostrarla como
  /// confirmación antes de enviar. Bug real que motiva esto: una
  /// búsqueda ambigua puede resolver al lugar equivocado (ej. "Parque
  /// Simón Bolívar" → un parque distinto en otro barrio) sin que nada
  /// en el precio lo delate. `null` mientras esa dirección todavía no
  /// se pudo geocodificar (typo, falta de escribir, etc.).
  final String? direccionFarmaciaResuelta;
  /// `false` cuando la dirección de farmacia sí se geocodificó pero es
  /// un lugar grande sin punto de entrega exacto (ej. "Universidad de
  /// Medellín" — el punto sigue siendo válido, solo aproximado).
  final bool direccionFarmaciaPrecisa;
  /// Otras coincidencias que Nominatim devolvió para la misma
  /// búsqueda — solo viene con datos cuando `direccionFarmaciaPrecisa`
  /// es `false`. Se ofrecen en un modal para que el Paciente elija en
  /// vez de quedarse con la aproximación automática.
  final List<CandidatoDireccion> direccionFarmaciaCandidatos;
  /// Ronda 14 — coordenadas ya confirmadas para `direccionFarmaciaResuelta`.
  /// Se guardan para mandarlas de vuelta al enviar el pedido y evitar
  /// que ese paso tenga que volver a geocodificar el mismo texto (ver
  /// `EnviarSolicitudUseCase` del lado de la API).
  final double? direccionFarmaciaLat;
  final double? direccionFarmaciaLng;
  final String? direccionEntregaResuelta;
  final bool direccionEntregaPrecisa;
  final List<CandidatoDireccion> direccionEntregaCandidatos;
  final double? direccionEntregaLat;
  final double? direccionEntregaLng;

  factory PrecioPedido.fromJson(Map<String, dynamic> json) {
    final direccionFarmaciaResuelta = json['direccionFarmaciaResuelta'] as String?;
    final direccionFarmaciaPrecisa =
        json['direccionFarmaciaPrecisa'] as bool? ?? true;
    final direccionFarmaciaCandidatos = _candidatosDesde(
      json['direccionFarmaciaCandidatos'],
    );
    final direccionFarmaciaLat = (json['direccionFarmaciaLat'] as num?)?.toDouble();
    final direccionFarmaciaLng = (json['direccionFarmaciaLng'] as num?)?.toDouble();
    final direccionEntregaResuelta = json['direccionEntregaResuelta'] as String?;
    final direccionEntregaPrecisa =
        json['direccionEntregaPrecisa'] as bool? ?? true;
    final direccionEntregaCandidatos = _candidatosDesde(
      json['direccionEntregaCandidatos'],
    );
    final direccionEntregaLat = (json['direccionEntregaLat'] as num?)?.toDouble();
    final direccionEntregaLng = (json['direccionEntregaLng'] as num?)?.toDouble();

    if (json['disponible'] == true) {
      return PrecioPedido.disponible(
        copago: json['copago'] as num,
        domicilio: json['domicilio'] as num,
        total: json['total'] as num,
        distanciaKm: json['distanciaKm'] as num,
        direccionFarmaciaResuelta: direccionFarmaciaResuelta,
        direccionFarmaciaPrecisa: direccionFarmaciaPrecisa,
        direccionFarmaciaCandidatos: direccionFarmaciaCandidatos,
        direccionFarmaciaLat: direccionFarmaciaLat,
        direccionFarmaciaLng: direccionFarmaciaLng,
        direccionEntregaResuelta: direccionEntregaResuelta,
        direccionEntregaPrecisa: direccionEntregaPrecisa,
        direccionEntregaCandidatos: direccionEntregaCandidatos,
        direccionEntregaLat: direccionEntregaLat,
        direccionEntregaLng: direccionEntregaLng,
      );
    }
    return PrecioPedido.noDisponible(
      json['motivo'] as String,
      direccionFarmaciaResuelta: direccionFarmaciaResuelta,
      direccionFarmaciaPrecisa: direccionFarmaciaPrecisa,
      direccionFarmaciaCandidatos: direccionFarmaciaCandidatos,
      direccionFarmaciaLat: direccionFarmaciaLat,
      direccionFarmaciaLng: direccionFarmaciaLng,
      direccionEntregaResuelta: direccionEntregaResuelta,
      direccionEntregaPrecisa: direccionEntregaPrecisa,
      direccionEntregaCandidatos: direccionEntregaCandidatos,
      direccionEntregaLat: direccionEntregaLat,
      direccionEntregaLng: direccionEntregaLng,
    );
  }

  static List<CandidatoDireccion> _candidatosDesde(dynamic valor) {
    if (valor is! List) return const [];
    return valor
        .map((item) => CandidatoDireccion.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
