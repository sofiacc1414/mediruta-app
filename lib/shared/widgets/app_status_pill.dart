import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Chip de estado de un pedido — un solo lugar que decide cómo se ve cada
/// `estado` (HU-07/HU-09), reusado en la lista de pedidos y en el detalle.
/// Nunca usa un color fuera de la paleta oficial ni un verde/rojo/naranja
/// "semántico" (DOCS/context.md, Parte A, sección 4) — la diferencia entre
/// "en curso"/"completado"/"cancelado" se comunica con fill vs. outline,
/// ícono y cuál de los 5 colores oficiales, no con un hue nuevo.
class AppStatusPill extends StatelessWidget {
  const AppStatusPill({super.key, required this.estado});

  final String estado;

  static const _etiquetas = {
    'borrador': 'Borrador',
    'pendiente_revision': 'Pedido generado',
    'en_asignacion': 'Buscando domiciliario',
    'asignado_en_camino_farmacia': 'En camino a la farmacia',
    'medicamentos_recogidos': 'Medicamentos recogidos',
    'en_camino_entrega': 'Yendo a tu dirección',
    'en_sitio': 'En sitio',
    'entregado': 'Entregado',
    'cancelada': 'Cancelada',
  };

  @override
  Widget build(BuildContext context) {
    final estilo = _estiloPara(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: estilo.relleno,
        borderRadius: BorderRadius.circular(999),
        border: estilo.borde != null ? Border.all(color: estilo.borde!) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (estilo.icono != null) ...[
            Icon(estilo.icono, size: 14, color: estilo.texto),
            const SizedBox(width: 4),
          ],
          Text(
            _etiquetas[estado] ?? estado,
            style: TextStyle(
              color: estilo.texto,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _EstiloPill _estiloPara(String estado) {
    switch (estado) {
      case 'en_asignacion':
        return _EstiloPill(
          relleno: AppColors.white,
          texto: AppColors.navy,
          borde: AppColors.skyBlue,
          icono: Icons.search,
        );
      case 'asignado_en_camino_farmacia':
        return _EstiloPill(
          relleno: AppColors.teal,
          texto: AppColors.white,
          icono: Icons.moped_outlined,
        );
      case 'medicamentos_recogidos':
        return _EstiloPill(
          relleno: AppColors.teal,
          texto: AppColors.white,
          icono: Icons.inventory_2_outlined,
        );
      case 'en_camino_entrega':
        return _EstiloPill(
          relleno: AppColors.navy,
          texto: AppColors.white,
          icono: Icons.local_shipping_outlined,
        );
      case 'en_sitio':
        return _EstiloPill(
          relleno: AppColors.navy,
          texto: AppColors.white,
          icono: Icons.location_on_outlined,
        );
      case 'entregado':
        return _EstiloPill(
          relleno: AppColors.beige,
          texto: AppColors.navy,
          icono: Icons.check_circle_outline,
        );
      case 'cancelada':
        return _EstiloPill(
          relleno: AppColors.white,
          texto: AppColors.teal,
          borde: AppColors.teal,
          icono: Icons.close,
        );
      default: // borrador, pendiente_revision
        return _EstiloPill(
          relleno: AppColors.white,
          texto: AppColors.navy,
          borde: AppColors.navy,
        );
    }
  }
}

class _EstiloPill {
  const _EstiloPill({
    required this.relleno,
    required this.texto,
    this.borde,
    this.icono,
  });

  final Color relleno;
  final Color texto;
  final Color? borde;
  final IconData? icono;
}
