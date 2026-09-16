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
    this.direccionEntregaResuelta,
    this.direccionEntregaPrecisa = true,
  });

  factory PrecioPedido.disponible({
    required num copago,
    required num domicilio,
    required num total,
    required num distanciaKm,
    String? direccionFarmaciaResuelta,
    bool direccionFarmaciaPrecisa = true,
    String? direccionEntregaResuelta,
    bool direccionEntregaPrecisa = true,
  }) {
    return PrecioPedido._(
      disponible: true,
      copago: copago,
      domicilio: domicilio,
      total: total,
      distanciaKm: distanciaKm,
      direccionFarmaciaResuelta: direccionFarmaciaResuelta,
      direccionFarmaciaPrecisa: direccionFarmaciaPrecisa,
      direccionEntregaResuelta: direccionEntregaResuelta,
      direccionEntregaPrecisa: direccionEntregaPrecisa,
    );
  }

  factory PrecioPedido.noDisponible(
    String motivo, {
    String? direccionFarmaciaResuelta,
    bool direccionFarmaciaPrecisa = true,
    String? direccionEntregaResuelta,
    bool direccionEntregaPrecisa = true,
  }) {
    return PrecioPedido._(
      disponible: false,
      motivo: motivo,
      direccionFarmaciaResuelta: direccionFarmaciaResuelta,
      direccionFarmaciaPrecisa: direccionFarmaciaPrecisa,
      direccionEntregaResuelta: direccionEntregaResuelta,
      direccionEntregaPrecisa: direccionEntregaPrecisa,
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
  final String? direccionEntregaResuelta;
  final bool direccionEntregaPrecisa;

  factory PrecioPedido.fromJson(Map<String, dynamic> json) {
    final direccionFarmaciaResuelta = json['direccionFarmaciaResuelta'] as String?;
    final direccionFarmaciaPrecisa =
        json['direccionFarmaciaPrecisa'] as bool? ?? true;
    final direccionEntregaResuelta = json['direccionEntregaResuelta'] as String?;
    final direccionEntregaPrecisa =
        json['direccionEntregaPrecisa'] as bool? ?? true;

    if (json['disponible'] == true) {
      return PrecioPedido.disponible(
        copago: json['copago'] as num,
        domicilio: json['domicilio'] as num,
        total: json['total'] as num,
        distanciaKm: json['distanciaKm'] as num,
        direccionFarmaciaResuelta: direccionFarmaciaResuelta,
        direccionFarmaciaPrecisa: direccionFarmaciaPrecisa,
        direccionEntregaResuelta: direccionEntregaResuelta,
        direccionEntregaPrecisa: direccionEntregaPrecisa,
      );
    }
    return PrecioPedido.noDisponible(
      json['motivo'] as String,
      direccionFarmaciaResuelta: direccionFarmaciaResuelta,
      direccionFarmaciaPrecisa: direccionFarmaciaPrecisa,
      direccionEntregaResuelta: direccionEntregaResuelta,
      direccionEntregaPrecisa: direccionEntregaPrecisa,
    );
  }
}
