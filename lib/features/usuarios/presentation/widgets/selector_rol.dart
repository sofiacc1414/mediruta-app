import 'package:flutter/material.dart';
import '../../../../shared/core/theme/app_colors.dart';

/// Selector de rol para el registro público — solo PACIENTE o
/// DOMICILIARIO (DOCS/context.md, Parte B, sección 4.1: ADMINISTRADOR y
/// ROOT no tienen registro público, ni siquiera se ofrecen acá).
class SelectorRol extends StatelessWidget {
  const SelectorRol({
    super.key,
    required this.tipoRegistroSeleccionado,
    required this.onChanged,
  });

  final String tipoRegistroSeleccionado;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'PACIENTE', label: Text('Paciente')),
        ButtonSegment(value: 'DOMICILIARIO', label: Text('Domiciliario')),
      ],
      selected: {tipoRegistroSeleccionado},
      onSelectionChanged: (seleccion) => onChanged(seleccion.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.navy
              : AppColors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.navy;
        }),
      ),
    );
  }
}
