class Calificacion {
  const Calificacion({
    required this.id,
    required this.solicitudId,
    required this.puntuacion,
    required this.comentario,
    required this.estado,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  final String id;
  final String solicitudId;
  final int puntuacion;
  final String? comentario;
  final String estado;
  final String creadoEn;
  final String actualizadoEn;

  factory Calificacion.fromJson(Map<String, dynamic> json) {
    return Calificacion(
      id: json['id'] as String,
      solicitudId: json['solicitudId'] as String,
      puntuacion: (json['puntuacion'] as num).toInt(),
      comentario: json['comentario'] as String?,
      estado: json['estado'] as String,
      creadoEn: json['creadoEn'] as String,
      actualizadoEn: json['actualizadoEn'] as String,
    );
  }
}

class PedidoCalificacion {
  const PedidoCalificacion({
    required this.id,
    required this.codigoPedido,
    required this.estado,
    required this.creadoEn,
    required this.cantidadMedicamentos,
    required this.tieneCalificacionActiva,
  });

  final String id;
  final String? codigoPedido;
  final String estado;
  final String creadoEn;
  final int cantidadMedicamentos;
  final bool tieneCalificacionActiva;

  factory PedidoCalificacion.fromJson(Map<String, dynamic> json) {
    return PedidoCalificacion(
      id: json['id'] as String,
      codigoPedido: json['codigoPedido'] as String?,
      estado: json['estado'] as String,
      creadoEn: json['creadoEn'] as String,
      cantidadMedicamentos: (json['cantidadMedicamentos'] as num).toInt(),
      tieneCalificacionActiva: json['tieneCalificacionActiva'] as bool,
    );
  }
}
