/// Una fila de "Mis solicitudes" (G02) — no trae el detalle completo
/// (los medicamentos viven en el detalle, G03).
class SolicitudResumen {
  const SolicitudResumen({required this.id, required this.estado, required this.creadoEn});

  final String id;
  final String estado;
  final String creadoEn;

  factory SolicitudResumen.fromJson(Map<String, dynamic> json) {
    return SolicitudResumen(
      id: json['id'] as String,
      estado: json['estado'] as String,
      creadoEn: json['creadoEn'] as String,
    );
  }
}
