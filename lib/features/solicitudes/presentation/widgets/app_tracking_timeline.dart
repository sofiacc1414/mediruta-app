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
  });

  final String estadoActual;
  final List<EventoHistorial> historial;

  /// Se muestra junto al paso que coincide con `estadoActual` — `null` si
  /// no aplica (ej. el detalle de solo lectura del Paciente).
  final Widget? accionPasoActual;

  static const _pasos = [
    'pendiente_revision',
    'en_asignacion',
    'asignado_en_camino_farmacia',
    'medicamentos_recogidos',
    'en_camino_entrega',
    'en_sitio',
    'entregado',
  ];

  static const _etiquetas = {
    'pendiente_revision': 'Pedido generado',
    'en_asignacion': 'Buscando domiciliario',
    'asignado_en_camino_farmacia': 'Domiciliario en camino a la farmacia',
    'medicamentos_recogidos': 'Medicamentos recogidos',
    'en_camino_entrega': 'Yendo a tu dirección',
    'en_sitio': 'En sitio',
    'entregado': 'Entregado',
  };

  @override
  Widget build(BuildContext context) {
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
