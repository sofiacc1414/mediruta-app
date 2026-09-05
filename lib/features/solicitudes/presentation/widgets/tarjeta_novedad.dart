import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_colors.dart';
import '../../domain/entities/novedad_resumen.dart';

/// HU-07/HU-09 (ronda 5, extraído en ronda 7 para reusarlo también en el
/// tab "Novedades" del Domiciliario) — una fila de "reportes sobre este
/// pedido", con su estado. El color se reserva a la paleta oficial
/// (context.md Parte A, §4) — la diferencia entre "aprobada"/"rechazada"
/// se marca con el ícono y el texto, no con verde/rojo fuera de paleta.
class TarjetaNovedad extends StatelessWidget {
  const TarjetaNovedad({super.key, required this.novedad});

  final NovedadResumen novedad;

  String get _etiquetaTipo => switch (novedad.tipo) {
    'edicion' => 'Corrección de datos',
    'codigo' => 'Código de entrega',
    _ => 'Pregunta',
  };

  (IconData, String) get _estado {
    if (!novedad.resuelta) {
      return (Icons.hourglass_top_outlined, 'En revisión por un administrador.');
    }
    if (novedad.tipo == 'edicion') {
      if (novedad.accionEdicion == 'aprobada') {
        return (Icons.check_circle_outline, 'Aprobada — el cambio ya se aplicó a tu pedido.');
      }
      if (novedad.accionEdicion == 'rechazada') {
        if (novedad.incluyeMedicamentosOReceta) {
          return (
            Icons.cancel_outlined,
            'Rechazada. Si todavía necesitás este cambio, cancelá el pedido y creá uno nuevo — '
                'si el domiciliario ya llegó a la farmacia, cancelar puede generar un cobro por el desplazamiento.',
          );
        }
        return (Icons.cancel_outlined, 'Rechazada.');
      }
    }
    return (Icons.check_circle_outline, 'Resuelta.');
  }

  @override
  Widget build(BuildContext context) {
    final (icono, mensaje) = _estado;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _etiquetaTipo,
            style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(novedad.detalle, style: const TextStyle(color: AppColors.teal, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, size: 16, color: AppColors.navy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mensaje,
                  style: const TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
