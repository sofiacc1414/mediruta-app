/// Una fila de "Mis solicitudes" (G02) — no trae el detalle completo
/// (los medicamentos viven en el detalle, G03).
class SolicitudResumen {
  const SolicitudResumen({
    required this.id,
    required this.codigoPedido,
    required this.estado,
    required this.creadoEn,
  });

  final String id;

  /// Solo existe una vez enviada (G05) — nulo mientras está en
  /// Borrador, todavía no es un "pedido".
  final String? codigoPedido;
  final String estado;
  final String creadoEn;

  factory SolicitudResumen.fromJson(Map<String, dynamic> json) {
    return SolicitudResumen(
      id: json['id'] as String,
      codigoPedido: json['codigoPedido'] as String?,
      estado: json['estado'] as String,
      creadoEn: json['creadoEn'] as String,
    );
  }
}
