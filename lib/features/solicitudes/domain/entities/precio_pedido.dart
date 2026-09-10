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
  });

  factory PrecioPedido.disponible({
    required num copago,
    required num domicilio,
    required num total,
    required num distanciaKm,
  }) {
    return PrecioPedido._(
      disponible: true,
      copago: copago,
      domicilio: domicilio,
      total: total,
      distanciaKm: distanciaKm,
    );
  }

  factory PrecioPedido.noDisponible(String motivo) {
    return PrecioPedido._(disponible: false, motivo: motivo);
  }

  final bool disponible;
  final num? copago;
  final num? domicilio;
  final num? total;
  final num? distanciaKm;

  /// 'sin_nivel_copago' | 'sin_ubicaciones' — solo si `!disponible`.
  final String? motivo;

  factory PrecioPedido.fromJson(Map<String, dynamic> json) {
    if (json['disponible'] == true) {
      return PrecioPedido.disponible(
        copago: json['copago'] as num,
        domicilio: json['domicilio'] as num,
        total: json['total'] as num,
        distanciaKm: json['distanciaKm'] as num,
      );
    }
    return PrecioPedido.noDisponible(json['motivo'] as String);
  }
}
