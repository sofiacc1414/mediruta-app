import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Círculo de color con un ícono centrado — reemplaza las ilustraciones
/// pintadas del mockup (no generables como asset acá) manteniendo el
/// mismo espíritu visual dentro de la paleta oficial.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icono,
    this.tamano = 96,
    this.colorFondo = AppColors.skyBlue,
    this.colorIcono = AppColors.navy,
  });

  final IconData icono;
  final double tamano;
  final Color colorFondo;
  final Color colorIcono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(color: colorFondo, shape: BoxShape.circle),
      child: Icon(icono, size: tamano * 0.45, color: colorIcono),
    );
  }
}
