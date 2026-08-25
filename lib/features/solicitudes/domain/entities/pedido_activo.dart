import 'evento_historial.dart';
import 'novedad_del_paciente.dart';

/// HU-09/HU-07 — el pedido que el Domiciliario tiene en curso ahora
/// mismo, con su historial (mismo `AppTrackingTimeline` que usa el
/// Paciente). A propósito NO trae `codigoEntrega` — el Paciente se lo
/// dicta recién al momento de la entrega, el Domiciliario no debe
/// conocerlo de antemano.
class PedidoActivo {
  const PedidoActivo({
    required this.id,
    required this.codigoPedido,
    required this.estado,
    required this.direccionEntrega,
    required this.direccionFarmacia,
    required this.creadoEn,
    required this.historial,
    required this.novedadPropiaAbierta,
  });

  final String id;
  final String? codigoPedido;
  final String estado;
  final String? direccionEntrega;
  final String? direccionFarmacia;
  final String creadoEn;
  final List<EventoHistorial> historial;

  /// Si el propio Domiciliario ya reportó una novedad sobre este pedido
  /// y sigue sin resolver — evita ofrecerle "Reportar novedad" de nuevo.
  final NovedadDelPaciente? novedadPropiaAbierta;

  factory PedidoActivo.fromJson(Map<String, dynamic> json) {
    return PedidoActivo(
      id: json['id'] as String,
      codigoPedido: json['codigoPedido'] as String?,
      estado: json['estado'] as String,
      direccionEntrega: json['direccionEntrega'] as String?,
      direccionFarmacia: json['direccionFarmacia'] as String?,
      creadoEn: json['creadoEn'] as String,
      historial: (json['historial'] as List<dynamic>)
          .map((e) => EventoHistorial.fromJson(e as Map<String, dynamic>))
          .toList(),
      novedadPropiaAbierta: json['novedadPropiaAbierta'] != null
          ? NovedadDelPaciente.fromJson(
              json['novedadPropiaAbierta'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
