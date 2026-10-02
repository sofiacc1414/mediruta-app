import 'package:flutter/material.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../domain/entities/evento_historial.dart';

/// Timeline vertical de los 7 pasos de un pedido (HU-07) — un punto por
/// estado (relleno navy si ya pasó, outline skyBlue si no), línea
/// conectora, etiqueta + hora tomada del `historial` real. Vive en
/// `solicitudes/presentation/widgets` (no en `shared/widgets`) porque la
/// secuencia de 7 pasos es conocimiento del dominio de pedidos, no un
/// primitivo genérico de UI.
///
/// Se reusa en el detalle del Paciente (solo lectura) y en "Mi pedido
/// activo" del Domiciliario, que además pasa `accionPasoActual` — el botón
/// para avanzar al siguiente paso, embebido junto al punto en curso.
class AppTrackingTimeline extends StatelessWidget {
  const AppTrackingTimeline({
    super.key,
    required this.estadoActual,
    required this.historial,
    this.accionPasoActual,
    this.vistaEntregaDomiciliario = false,
  });

  final String estadoActual;
  final List<EventoHistorial> historial;

  /// Se muestra junto al paso en curso — `null` si no aplica (ej. el
  /// detalle de solo lectura del Paciente).
  final Widget? accionPasoActual;

  /// En "Mi pedido activo" el avance del domiciliario son 4 pasos.
  /// Solo se marca un paso cuando la acción de ese paso ya se completó:
  /// al aceptar, únicamente "Pedido aceptado".
  final bool vistaEntregaDomiciliario;

  static const _pasos = [
    'pendiente_revision',
    'en_asignacion',
    'asignado_en_camino_farmacia',
    'en_farmacia',
    'medicamentos_recogidos',
    'en_camino_entrega',
    'en_sitio',
    'entregado',
  ];

  static const _etiquetas = {
    'pendiente_revision': 'Pedido generado',
    'en_asignacion': 'Buscando domiciliario',
    'asignado_en_camino_farmacia': 'Domiciliario en camino a la farmacia',
    'en_farmacia': 'Domiciliario en la farmacia',
    'medicamentos_recogidos': 'Medicamentos recogidos',
    'en_camino_entrega': 'Yendo a tu dirección',
    'en_sitio': 'En sitio',
    'entregado': 'Entregado',
  };

  /// Pasos que recorre el domiciliario después de aceptar. El estado
  /// real del pedido se traduce a cuántos de estos ya quedaron hechos.
  static const _pasosEntrega = [
    'pedido_aceptado',
    'en_camino_farmacia',
    'en_farmacia',
    'pedido_recogido',
    'en_camino',
    'en_sitio',
    'entregado',
  ];

  static const _etiquetasEntrega = {
    'pedido_aceptado': 'Pedido aceptado',
    'en_camino_farmacia': 'En camino a farmacia',
    'en_farmacia': 'En farmacia',
    'pedido_recogido': 'Pedido recogido',
    'en_camino': 'En camino al destino',
    'en_sitio': 'En sitio',
    'entregado': 'Entregado',
  };

  /// Cuántos pasos de entrega ya están completos. Aceptar deja hechos
  /// "Pedido aceptado" y "En camino a farmacia". La cédula solo existe
  /// cuando el paso "En farmacia" ya se marcó.
  static int pasosEntregaCompletados(String estado) {
    return switch (estado) {
      'en_farmacia' => 3,
      'medicamentos_recogidos' => 4,
      'en_camino_entrega' => 5,
      'en_sitio' => 6,
      'entregado' => 7,
      _ => 2,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (vistaEntregaDomiciliario) {
      final completados = pasosEntregaCompletados(estadoActual);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _pasosEntrega.length; i++)
            _FilaPaso(
              etiqueta: _etiquetasEntrega[_pasosEntrega[i]]!,
              alcanzado: i < completados,
              esUltimo: i == _pasosEntrega.length - 1,
              fechaHora: _fechaEntrega(_pasosEntrega[i]),
              accion: i == completados ? accionPasoActual : null,
            ),
        ],
      );
    }

    final indiceActual = _pasos.indexOf(estadoActual);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _pasos.length; i++)
          _FilaPaso(
            etiqueta: _etiquetas[_pasos[i]]!,
            alcanzado: indiceActual >= 0 && i <= indiceActual,
            esUltimo: i == _pasos.length - 1,
            fechaHora: _fechaPara(_pasos[i]),
            accion: i == indiceActual ? accionPasoActual : null,
          ),
      ],
    );
  }

  String? _fechaEntrega(String paso) {
    final estado = switch (paso) {
      'pedido_aceptado' || 'en_camino_farmacia' => 'asignado_en_camino_farmacia',
      'en_farmacia' => 'en_farmacia',
      'pedido_recogido' => 'medicamentos_recogidos',
      'en_camino' => 'en_camino_entrega',
      'en_sitio' => 'en_sitio',
      'entregado' => 'entregado',
      _ => paso,
    };
    return _fechaPara(estado);
  }

  String? _fechaPara(String estado) {
    for (final evento in historial) {
      if (evento.estado == estado) return _formatearFechaHora(evento.creadoEn);
    }
    return null;
  }
}

/// La API manda los timestamps en UTC (`timestamptz`) — sin `.toLocal()`
/// se mostraba la hora UTC tal cual (ej. 06:47 cuando en Colombia eran
/// las 01:50), un bug real reportado en vivo.
String _formatearFechaHora(String iso) {
  final fecha = DateTime.tryParse(iso)?.toLocal();
  if (fecha == null) return iso;
  final dia = fecha.day.toString().padLeft(2, '0');
  const meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  final hora = fecha.hour.toString().padLeft(2, '0');
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '$dia ${meses[fecha.month - 1]} · $hora:$minuto';
}

class _FilaPaso extends StatelessWidget {
  const _FilaPaso({
    required this.etiqueta,
    required this.alcanzado,
    required this.esUltimo,
    this.fechaHora,
    this.accion,
  });

  final String etiqueta;
  final bool alcanzado;
  final bool esUltimo;
  final String? fechaHora;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: alcanzado ? AppColors.navy : AppColors.white,
                  border: Border.all(
                    color: alcanzado ? AppColors.navy : AppColors.skyBlue,
                    width: 2,
                  ),
                ),
              ),
              if (!esUltimo)
                Expanded(
                  child: Container(
                    width: 2,
                    color: alcanzado ? AppColors.navy : AppColors.skyBlue,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: esUltimo ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etiqueta,
                    style: TextStyle(
                      color: alcanzado ? AppColors.navy : AppColors.teal,
                      fontWeight: alcanzado ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (fechaHora != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      fechaHora!,
                      style: const TextStyle(color: AppColors.teal, fontSize: 12),
                    ),
                  ],
                  if (accion != null) ...[
                    const SizedBox(height: 10),
                    accion!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
