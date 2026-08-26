/// Una fila del historial de pedidos que el Domiciliario ya atendió
/// (en curso, entregados o cancelados) — "Mis pedidos" de su lado.
class PedidoHistorial {
  const PedidoHistorial({
    required this.id,
    required this.codigoPedido,
    required this.estado,
    required this.direccionEntrega,
    required this.creadoEn,
  });

  final String id;
  final String? codigoPedido;
  final String estado;
  final String? direccionEntrega;
  final String creadoEn;

  factory PedidoHistorial.fromJson(Map<String, dynamic> json) {
    return PedidoHistorial(
      id: json['id'] as String,
      codigoPedido: json['codigoPedido'] as String?,
      estado: json['estado'] as String,
      direccionEntrega: json['direccionEntrega'] as String?,
      creadoEn: json['creadoEn'] as String,
    );
  }
}
