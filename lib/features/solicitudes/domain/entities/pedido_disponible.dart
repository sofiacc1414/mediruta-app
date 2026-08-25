/// HU-09 — un pedido en `en_asignacion`, visto por un Domiciliario en su
/// pool, ya ordenado por distancia real a la farmacia.
class PedidoDisponible {
  const PedidoDisponible({
    required this.id,
    required this.codigoPedido,
    required this.direccionFarmacia,
    required this.direccionEntrega,
    required this.distanciaMetros,
    required this.creadoEn,
  });

  final String id;
  final String? codigoPedido;
  final String? direccionFarmacia;
  final String? direccionEntrega;
  final double distanciaMetros;
  final String creadoEn;

  double get distanciaKm => distanciaMetros / 1000;

  factory PedidoDisponible.fromJson(Map<String, dynamic> json) {
    return PedidoDisponible(
      id: json['id'] as String,
      codigoPedido: json['codigoPedido'] as String?,
      direccionFarmacia: json['direccionFarmacia'] as String?,
      direccionEntrega: json['direccionEntrega'] as String?,
      distanciaMetros: (json['distanciaMetros'] as num).toDouble(),
      creadoEn: json['creadoEn'] as String,
    );
  }
}
