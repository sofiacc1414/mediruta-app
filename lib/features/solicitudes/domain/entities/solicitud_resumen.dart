/// Una fila de "Mis solicitudes" (G02) — no trae el detalle completo.
class SolicitudResumen {
  const SolicitudResumen({
    required this.id,
    required this.medicamentoNombre,
    required this.estado,
    required this.creadoEn,
  });

  final String id;
  final String? medicamentoNombre;
  final String estado;
  final String creadoEn;

  factory SolicitudResumen.fromJson(Map<String, dynamic> json) {
    return SolicitudResumen(
      id: json['id'] as String,
      medicamentoNombre: json['medicamentoNombre'] as String?,
      estado: json['estado'] as String,
      creadoEn: json['creadoEn'] as String,
    );
  }
}
