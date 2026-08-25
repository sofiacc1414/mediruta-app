import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Card ancha de fondo sólido (Home) — para avisos destacados (ej.
/// "Completá tu perfil para poder pedir"). Fill navy o teal, nunca un color
/// fuera de la paleta ni un degradado externo (Parte A, sección 4).
class AppPromoBanner extends StatelessWidget {
  const AppPromoBanner({
    super.key,
    required this.titulo,
    this.icono = Icons.local_shipping_outlined,
    this.accion,
    this.onTapAccion,
    this.fondo = AppColors.navy,
  });

  final String titulo;
  final IconData icono;
  final String? accion;
  final VoidCallback? onTapAccion;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ) ??
                      const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (accion != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onTapAccion,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(accion!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: AppColors.white, size: 28),
          ),
        ],
      ),
    );
  }
}
