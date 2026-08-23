import 'datos_solicitud.dart';
import 'evento_historial.dart';

/// Detalle completo de una solicitud (G03), datos + historial de estados.
class Solicitud {
  const Solicitud({
    required this.id,
    required this.estado,
    required this.datos,
    required this.creadoEn,
    required this.enviadoEn,
    required this.canceladoEn,
    required this.historial,
  });

  final String id;
  final String estado; // 'borrador' | 'pendiente_revision' | 'cancelada'
  final DatosSolicitud datos;
  final String creadoEn;
  final String? enviadoEn;
  final String? canceladoEn;
  final List<EventoHistorial> historial;

  bool get esBorrador => estado == 'borrador';

  factory Solicitud.fromJson(Map<String, dynamic> json) {
    return Solicitud(
      id: json['id'] as String,
      estado: json['estado'] as String,
      datos: DatosSolicitud.fromJson(json),
      creadoEn: json['creadoEn'] as String,
      enviadoEn: json['enviadoEn'] as String?,
      canceladoEn: json['canceladoEn'] as String?,
      historial: (json['historial'] as List<dynamic>)
          .map((e) => EventoHistorial.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
