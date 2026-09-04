import 'package:flutter/material.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_selection_card.dart';

/// Selector de rol para el registro público — solo PACIENTE o
/// DOMICILIARIO (DOCS/context.md, Parte B, sección 4.1: ADMINISTRADOR y
/// ROOT no tienen registro público, ni siquiera se ofrecen acá, a
/// diferencia del mockup original que sí los mostraba).
class SelectorRol extends StatelessWidget {
  const SelectorRol({
    super.key,
    required this.tipoRegistroSeleccionado,
    required this.onChanged,
  });

  final String tipoRegistroSeleccionado;
  final ValueChanged<String> onChanged;

  static const _opciones = [
    (
      codigo: 'PACIENTE',
      label: 'Paciente',
      sublabel: 'Recibe tus medicamentos',
      icono: Icons.person_outline,
    ),
    (
      codigo: 'DOMICILIARIO',
      label: 'Domiciliario',
      sublabel: 'Lleva bienestar a otros',
      icono: Icons.moped_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final opcion in _opciones) ...[
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AppSelectionCard(
                  icono: opcion.icono,
                  label: opcion.label,
                  sublabel: opcion.sublabel,
                  seleccionado: tipoRegistroSeleccionado == opcion.codigo,
                  onTap: () => onChanged(opcion.codigo),
                ),
                if (tipoRegistroSeleccionado == opcion.codigo)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: IgnorePointer(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.skyBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (opcion != _opciones.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}
