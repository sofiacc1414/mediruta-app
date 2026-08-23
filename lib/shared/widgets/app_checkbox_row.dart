import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Checkbox + texto, temática Navy — para "Recordarme" y aceptación de
/// términos. `label` puede incluir un `onLabelTap` para textos con un
/// link inline (ej. "Acepto los Términos y Condiciones").
class AppCheckboxRow extends StatelessWidget {
  const AppCheckboxRow({
    super.key,
    required this.valor,
    required this.onChanged,
    required this.label,
  });

  final bool valor;
  final ValueChanged<bool> onChanged;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: valor,
          activeColor: AppColors.navy,
          onChanged: (v) => onChanged(v ?? false),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!valor),
            child: label,
          ),
        ),
      ],
    );
  }
}
