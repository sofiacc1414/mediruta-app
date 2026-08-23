/// Un cambio de estado en la línea de tiempo de una solicitud (G03).
class EventoHistorial {
  const EventoHistorial({required this.estado, required this.creadoEn});

  final String estado;
  final String creadoEn;

  factory EventoHistorial.fromJson(Map<String, dynamic> json) {
    return EventoHistorial(
      estado: json['estado'] as String,
      creadoEn: json['creadoEn'] as String,
    );
  }
}
