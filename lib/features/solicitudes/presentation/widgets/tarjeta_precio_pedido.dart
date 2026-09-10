import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_colors.dart';
import '../../domain/entities/precio_pedido.dart';

/// Precio del pedido (copago + domicilio) — ver `PrecioPedido`. Si
/// todavía no se puede calcular (falta elegir nivel de copago, o falta
/// geocodificar alguna dirección), muestra un aviso en vez del
/// desglose. La usan tanto `SolicitudDetalleScreen` (precio ya
/// definitivo, de un pedido guardado) como `NuevaSolicitudScreen`
/// (estimado en vivo mientras se arma el borrador, antes de enviar) —
/// mismo widget, `mensajeSinUbicaciones` cambia según el contexto.
class TarjetaPrecioPedido extends StatelessWidget {
  const TarjetaPrecioPedido({
    super.key,
    required this.precio,
    this.titulo = 'Precio del pedido',
    this.mensajeSinUbicaciones =
        'Todavía no se puede calcular — falta confirmar las direcciones.',
  });

  final PrecioPedido precio;
  final String titulo;
  final String mensajeSinUbicaciones;

  String _formatearCop(num valor) {
    final texto = valor.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < texto.length; i++) {
      if (i > 0 && (texto.length - i) % 3 == 0) buffer.write('.');
      buffer.write(texto[i]);
    }
    return '\$$buffer';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            titulo,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          if (!precio.disponible)
            Text(
              precio.motivo == 'sin_nivel_copago'
                  ? 'Elegí tu nivel de copago en tu perfil para ver el precio.'
                  : mensajeSinUbicaciones,
              style: const TextStyle(color: AppColors.teal, fontSize: 13),
            )
          else ...[
            _filaPrecio('Copago', _formatearCop(precio.copago!)),
            const SizedBox(height: 6),
            _filaPrecio(
              'Domicilio (${precio.distanciaKm} km)',
              _formatearCop(precio.domicilio!),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.skyBlue),
            const SizedBox(height: 10),
            _filaPrecio('Total', _formatearCop(precio.total!), destacado: true),
          ],
        ],
      ),
    );
  }

  Widget _filaPrecio(String label, String valor, {bool destacado = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: destacado ? AppColors.navy : AppColors.teal,
            fontSize: destacado ? 15 : 13,
            fontWeight: destacado ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            color: AppColors.navy,
            fontSize: destacado ? 17 : 14,
            fontWeight: destacado ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
