import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_colors.dart';

/// Reemplaza cualquier contenido que exija el rol DOMICILIARIO
/// habilitado (Home, "Mis pedidos") mientras la cuenta todavía está
/// 'pendiente_validacion' (o 'rechazado') — antes esas pantallas
/// intentaban llamar a la API igual y mostraban "Tu cuenta no tiene
/// ese rol asignado" (cierto, pero confuso: el rol sí está, falta la
/// aprobación). Solo ícono/texto para distinguir pendiente de
/// rechazado, ningún color fuera de la paleta oficial (context.md
/// Parte A, §4).
class TarjetaEstadoValidacionDomiciliario extends StatelessWidget {
  const TarjetaEstadoValidacionDomiciliario({super.key, required this.estado});

  final String? estado;

  @override
  Widget build(BuildContext context) {
    final rechazado = estado == 'rechazado';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            rechazado ? Icons.cancel_outlined : Icons.hourglass_top_outlined,
            color: AppColors.navy,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            rechazado ? 'Solicitud rechazada' : 'Cuenta en proceso de validación',
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            rechazado
                ? 'Un administrador rechazó tu solicitud para ser Domiciliario. '
                    'Revisá el motivo y tus datos desde tu Perfil.'
                : 'Un administrador está revisando tus datos y documentos. '
                    'Vas a poder recibir pedidos apenas se apruebe tu cuenta.',
            style: const TextStyle(color: AppColors.teal, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}
