import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Jerarquía de botones oficial (DOCS/context.md, Parte A, secciones 13 y
/// 23): Primary (Navy), Secondary (borde, fondo blanco/sky blue). Forma
/// píldora (`StadiumBorder`) para acercarse al lenguaje visual del mockup.
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

  static const _minimoSize = Size(double.infinity, 52);
  static const _forma = StadiumBorder();
  static const _estiloTexto = TextStyle(fontWeight: FontWeight.w600, fontSize: 16);

  @override
  Widget build(BuildContext context) {
    if (variante == AppButtonVariante.secondary) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.teal, width: 1.5),
          minimumSize: _minimoSize,
          shape: _forma,
          textStyle: _estiloTexto,
        ),
        child: Text(label),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: _minimoSize,
        shape: _forma,
        textStyle: _estiloTexto,
        elevation: 0,
      ),
      child: Text(label),
    );
  }
}
