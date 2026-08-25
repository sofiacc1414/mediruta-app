/// HU-07 — una novedad abierta sobre el propio pedido, visible para el
/// Paciente (no reemplaza el `estado` real del pedido, ver `Solicitud`).
class NovedadDelPaciente {
  const NovedadDelPaciente({
    required this.id,
    required this.detalle,
    required this.creadoEn,
  });

  final String id;
  final String detalle;
  final String creadoEn;

  factory NovedadDelPaciente.fromJson(Map<String, dynamic> json) {
    return NovedadDelPaciente(
      id: json['id'] as String,
      detalle: json['detalle'] as String,
      creadoEn: json['creadoEn'] as String,
    );
  }
}
