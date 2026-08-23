import 'evento_historial.dart';
import 'medicamento.dart';

/// Detalle completo de una solicitud (G03): medicamentos, receta y
/// cédula del paciente (URLs firmadas) + historial de estados.
class Solicitud {
  const Solicitud({
    required this.id,
    required this.estado,
    required this.recetaUrl,
    required this.recetaFechaVencimiento,
    required this.direccionEntrega,
    required this.creadoEn,
    required this.enviadoEn,
    required this.canceladoEn,
    required this.cedulaUrl,
    required this.medicamentos,
    required this.historial,
  });

  final String id;
  final String estado; // 'borrador' | 'pendiente_revision' | 'cancelada'
  final String? recetaUrl;
  final String? recetaFechaVencimiento;
  final String? direccionEntrega;
  final String creadoEn;
  final String? enviadoEn;
  final String? canceladoEn;

  /// URL firmada de `perfil_paciente.foto_cedula_path` (HU-02) —
  /// referencia viva, nunca se copia a la solicitud.
  final String? cedulaUrl;
  final List<Medicamento> medicamentos;
  final List<EventoHistorial> historial;

  bool get esBorrador => estado == 'borrador';

  factory Solicitud.fromJson(Map<String, dynamic> json) {
    return Solicitud(
      id: json['id'] as String,
      estado: json['estado'] as String,
      recetaUrl: json['recetaUrl'] as String?,
      recetaFechaVencimiento: json['recetaFechaVencimiento'] as String?,
      direccionEntrega: json['direccionEntrega'] as String?,
      creadoEn: json['creadoEn'] as String,
      enviadoEn: json['enviadoEn'] as String?,
      canceladoEn: json['canceladoEn'] as String?,
      cedulaUrl: json['cedulaUrl'] as String?,
      medicamentos: (json['medicamentos'] as List<dynamic>)
          .map((e) => Medicamento.fromJson(e as Map<String, dynamic>))
          .toList(),
      historial: (json['historial'] as List<dynamic>)
          .map((e) => EventoHistorial.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
