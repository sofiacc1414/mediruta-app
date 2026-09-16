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
    this.direccionEntregaResuelta,
    this.direccionEntregaPrecisa = true,
    this.direccionEntregaCandidatos = const [],
  });

  factory PrecioPedido.disponible({
    required num copago,
    required num domicilio,
    required num total,
    required num distanciaKm,
    String? direccionFarmaciaResuelta,
    bool direccionFarmaciaPrecisa = true,
    List<CandidatoDireccion> direccionFarmaciaCandidatos = const [],
    String? direccionEntregaResuelta,
    bool direccionEntregaPrecisa = true,
    List<CandidatoDireccion> direccionEntregaCandidatos = const [],
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
      direccionEntregaResuelta: direccionEntregaResuelta,
      direccionEntregaPrecisa: direccionEntregaPrecisa,
      direccionEntregaCandidatos: direccionEntregaCandidatos,
    );
  }

  factory PrecioPedido.noDisponible(
    String motivo, {
    String? direccionFarmaciaResuelta,
    bool direccionFarmaciaPrecisa = true,
    List<CandidatoDireccion> direccionFarmaciaCandidatos = const [],
    String? direccionEntregaResuelta,
    bool direccionEntregaPrecisa = true,
    List<CandidatoDireccion> direccionEntregaCandidatos = const [],
  }) {
    return PrecioPedido._(
      disponible: false,
      motivo: motivo,
      direccionFarmaciaResuelta: direccionFarmaciaResuelta,
      direccionFarmaciaPrecisa: direccionFarmaciaPrecisa,
      direccionFarmaciaCandidatos: direccionFarmaciaCandidatos,
      direccionEntregaResuelta: direccionEntregaResuelta,
      direccionEntregaPrecisa: direccionEntregaPrecisa,
      direccionEntregaCandidatos: direccionEntregaCandidatos,
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
  final String? direccionEntregaResuelta;
  final bool direccionEntregaPrecisa;
  final List<CandidatoDireccion> direccionEntregaCandidatos;

  factory PrecioPedido.fromJson(Map<String, dynamic> json) {
    final direccionFarmaciaResuelta = json['direccionFarmaciaResuelta'] as String?;
    final direccionFarmaciaPrecisa =
        json['direccionFarmaciaPrecisa'] as bool? ?? true;
    final direccionFarmaciaCandidatos = _candidatosDesde(
      json['direccionFarmaciaCandidatos'],
    );
    final direccionEntregaResuelta = json['direccionEntregaResuelta'] as String?;
    final direccionEntregaPrecisa =
        json['direccionEntregaPrecisa'] as bool? ?? true;
    final direccionEntregaCandidatos = _candidatosDesde(
      json['direccionEntregaCandidatos'],
    );

    if (json['disponible'] == true) {
      return PrecioPedido.disponible(
        copago: json['copago'] as num,
        domicilio: json['domicilio'] as num,
        total: json['total'] as num,
        distanciaKm: json['distanciaKm'] as num,
        direccionFarmaciaResuelta: direccionFarmaciaResuelta,
        direccionFarmaciaPrecisa: direccionFarmaciaPrecisa,
        direccionFarmaciaCandidatos: direccionFarmaciaCandidatos,
        direccionEntregaResuelta: direccionEntregaResuelta,
        direccionEntregaPrecisa: direccionEntregaPrecisa,
        direccionEntregaCandidatos: direccionEntregaCandidatos,
      );
    }
    return PrecioPedido.noDisponible(
      json['motivo'] as String,
      direccionFarmaciaResuelta: direccionFarmaciaResuelta,
      direccionFarmaciaPrecisa: direccionFarmaciaPrecisa,
      direccionFarmaciaCandidatos: direccionFarmaciaCandidatos,
      direccionEntregaResuelta: direccionEntregaResuelta,
      direccionEntregaPrecisa: direccionEntregaPrecisa,
      direccionEntregaCandidatos: direccionEntregaCandidatos,
    );
  }

  static List<CandidatoDireccion> _candidatosDesde(dynamic valor) {
    if (valor is! List) return const [];
    return valor
        .map((item) => CandidatoDireccion.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
