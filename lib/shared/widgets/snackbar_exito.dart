import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Aviso de éxito: fondo blanco, borde gris claro y texto azul
/// corporativo (navy). El SnackBar de Material 3 pinta `inverseSurface`
/// (negro) aunque se le pase `backgroundColor`, así que el fondo real
/// va en la tarjeta de adentro y el SnackBar queda transparente.
SnackBar snackBarExito(String mensaje) {
  return SnackBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    padding: EdgeInsets.zero,
    content: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        mensaje,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    ),
  );
}
