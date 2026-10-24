import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_colors.dart';
import '../../domain/entities/medios_pago_habilitados.dart';

/// Módulo 4 — qué medio de pago usar para este pedido. Solo ofrece los
/// medios que el admin tiene habilitados (`medios`); si todavía no
/// cargaron (`null`), ofrece solo "Efectivo" (comportamiento histórico).
class SelectorMetodoPago extends StatelessWidget {
  const SelectorMetodoPago({
    super.key,
    required this.metodoSeleccionado,
    required this.medios,
    required this.onCambiar,
    this.enabled = true,
  });

  final String metodoSeleccionado;
  final MediosPagoHabilitados? medios;
  final ValueChanged<String> onCambiar;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final opciones = <(String, String, IconData)>[
      if (medios?.pagoEfectivoHabilitado ?? true)
        ('efectivo', 'Efectivo', Icons.payments_outlined),
      if (medios?.pagoTarjetaHabilitado ?? false)
        ('tarjeta', 'Tarjeta', Icons.credit_card_outlined),
      if (medios?.pagoTransferenciaHabilitado ?? false)
        ('transferencia', 'Transferencia', Icons.account_balance_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medio de pago',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: opciones.map((opcion) {
            final (valor, etiqueta, icono) = opcion;
            final seleccionado = valor == metodoSeleccionado;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icono,
                    size: 16,
                    color: seleccionado ? AppColors.sobreEnfasis : AppColors.teal,
                  ),
                  const SizedBox(width: 6),
                  Text(etiqueta),
                ],
              ),
              selected: seleccionado,
              onSelected: enabled ? (_) => onCambiar(valor) : null,
              selectedColor: AppColors.enfasis,
              labelStyle: TextStyle(
                color: seleccionado ? AppColors.sobreEnfasis : AppColors.navy,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: AppColors.white,
              side: BorderSide(color: AppColors.border),
            );
          }).toList(),
        ),
      ],
    );
  }
}
