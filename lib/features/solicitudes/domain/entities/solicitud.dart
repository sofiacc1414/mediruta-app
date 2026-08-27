import 'evento_historial.dart';
import 'medicamento.dart';
import 'novedad_del_paciente.dart';

/// Detalle completo de una solicitud (G03): medicamentos, receta y
/// cédula del paciente (URLs firmadas) + historial de estados.
class Solicitud {
  const Solicitud({
    required this.id,
    required this.codigoPedido,
    required this.estado,
    required this.recetaUrl,
    required this.recetaFechaVencimiento,
    required this.direccionEntrega,
    required this.direccionFarmacia,
    required this.creadoEn,
    required this.enviadoEn,
    required this.canceladoEn,
    required this.cedulaFrenteUrl,
    required this.cedulaReversoUrl,
    required this.medicamentos,
    required this.historial,
    required this.codigoEntrega,
    required this.novedadAbierta,
  });

  final String id;

  /// Solo existe una vez enviada (G05) — nulo mientras está en
  /// Borrador, todavía no es un "pedido".
  final String? codigoPedido;

  /// 'borrador' | 'pendiente_revision' | 'en_asignacion' |
  /// 'asignado_en_camino_farmacia' | 'medicamentos_recogidos' |
  /// 'en_camino_entrega' | 'en_sitio' | 'entregado' | 'cancelada'.
  final String estado;
  final String? recetaUrl;
  final String? recetaFechaVencimiento;
  final String? direccionEntrega;

  /// Dónde el domiciliario retira el medicamento — distinta de
  /// `direccionEntrega`, no un duplicado.
  final String? direccionFarmacia;
  final String creadoEn;
  final String? enviadoEn;
  final String? canceladoEn;

  /// URLs firmadas de `perfil_paciente.foto_cedula_frente_path`/
  /// `foto_cedula_reverso_path` (HU-02) — referencia viva, nunca se
  /// copian a la solicitud.
  final String? cedulaFrenteUrl;
  final String? cedulaReversoUrl;
  final List<Medicamento> medicamentos;
  final List<EventoHistorial> historial;

  /// HU-09 — existe desde que se envía, igual que `codigoPedido`. Se lo
  /// dicta al Domiciliario al recibir el pedido.
  final String? codigoEntrega;

  /// HU-07 — si hay una novedad abierta sobre este pedido, se muestra
  /// acá; no reemplaza `estado`.
  final NovedadDelPaciente? novedadAbierta;

  bool get esBorrador => estado == 'borrador';

  factory Solicitud.fromJson(Map<String, dynamic> json) {
    return Solicitud(
      id: json['id'] as String,
      codigoPedido: json['codigoPedido'] as String?,
      estado: json['estado'] as String,
      recetaUrl: json['recetaUrl'] as String?,
      recetaFechaVencimiento: json['recetaFechaVencimiento'] as String?,
      direccionEntrega: json['direccionEntrega'] as String?,
      direccionFarmacia: json['direccionFarmacia'] as String?,
      creadoEn: json['creadoEn'] as String,
      enviadoEn: json['enviadoEn'] as String?,
      canceladoEn: json['canceladoEn'] as String?,
      cedulaFrenteUrl: json['cedulaFrenteUrl'] as String?,
      cedulaReversoUrl: json['cedulaReversoUrl'] as String?,
      medicamentos: (json['medicamentos'] as List<dynamic>)
          .map((e) => Medicamento.fromJson(e as Map<String, dynamic>))
          .toList(),
      historial: (json['historial'] as List<dynamic>)
          .map((e) => EventoHistorial.fromJson(e as Map<String, dynamic>))
          .toList(),
      codigoEntrega: json['codigoEntrega'] as String?,
      novedadAbierta: json['novedadAbierta'] != null
          ? NovedadDelPaciente.fromJson(json['novedadAbierta'] as Map<String, dynamic>)
          : null,
    );
  }
}
