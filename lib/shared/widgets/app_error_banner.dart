import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Feedback de error dentro de la paleta oficial — sin rojo ni ningún
/// color fuera de Navy/Teal/SkyBlue/Beige/White (DOCS/context.md, Parte A,
/// sección 4: contraste + iconografía + texto, nunca un color nuevo).
class AppErrorBanner extends StatelessWidget {
  const AppErrorBanner({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.skyBlue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.navy, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.navy, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
