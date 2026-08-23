import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Jerarquía de botones oficial (DOCS/context.md, Parte A, secciones 13 y
/// 23): Primary (Navy), Secondary (borde, fondo blanco/sky blue).
enum AppButtonVariante { primary, secondary }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variante = AppButtonVariante.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariante variante;

  @override
  Widget build(BuildContext context) {
    if (variante == AppButtonVariante.secondary) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.teal),
        ),
        child: Text(label),
      );
    }

    return ElevatedButton(onPressed: onPressed, child: Text(label));
  }
}
