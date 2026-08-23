import 'package:flutter/material.dart';
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
    (codigo: 'PACIENTE', label: 'Paciente', icono: Icons.person_outline),
    (codigo: 'DOMICILIARIO', label: 'Domiciliario', icono: Icons.moped_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final opcion in _opciones) ...[
          Expanded(
            child: AppSelectionCard(
              icono: opcion.icono,
              label: opcion.label,
              seleccionado: tipoRegistroSeleccionado == opcion.codigo,
              onTap: () => onChanged(opcion.codigo),
            ),
          ),
          if (opcion != _opciones.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}
