class Notificacion {
  const Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.referenciaTipo,
    required this.referenciaId,
    required this.leida,
    required this.creadoEn,
  });

  final String id;
  final String tipo;
  final String titulo;
  final String mensaje;
  final String referenciaTipo;
  final String? referenciaId;
  final bool leida;
  final DateTime creadoEn;

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      referenciaTipo: json['referenciaTipo'] as String,
      referenciaId: json['referenciaId'] as String?,
      leida: json['leida'] == true,
      creadoEn: DateTime.parse(json['creadoEn'] as String).toLocal(),
    );
  }
}
