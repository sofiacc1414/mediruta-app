import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'app_icon_badge.dart';

/// Tarjeta seleccionable con ícono en círculo + label (+ sublabel
/// opcional, ej. "pendiente") — mismo componente visual para el selector
/// de rol en `registro_screen.dart` y el selector de modo en
/// `home_screen.dart`, para que ambas pantallas se vean consistentes
/// (DOCS/context.md, Parte A, sección 22).
class AppSelectionCard extends StatelessWidget {
  const AppSelectionCard({
    super.key,
    required this.icono,
    required this.label,
    required this.seleccionado,
    required this.onTap,
    this.sublabel,
  });

  final IconData icono;
  final String label;
  final String? sublabel;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? AppColors.navy : AppColors.skyBlue,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconBadge(
              icono: icono,
              tamano: 56,
              colorFondo: seleccionado ? AppColors.navy : AppColors.skyBlue,
              colorIcono: seleccionado ? AppColors.white : AppColors.navy,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            if (sublabel != null)
              Text(
                sublabel!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.teal, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
