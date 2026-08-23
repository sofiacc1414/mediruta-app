import 'package:flutter/material.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_icon_badge.dart';

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
          Expanded(child: _TarjetaRol(opcion: opcion, seleccionado: tipoRegistroSeleccionado == opcion.codigo, onChanged: onChanged)),
          if (opcion != _opciones.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _TarjetaRol extends StatelessWidget {
  const _TarjetaRol({
    required this.opcion,
    required this.seleccionado,
    required this.onChanged,
  });

  final ({String codigo, String label, IconData icono}) opcion;
  final bool seleccionado;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onChanged(opcion.codigo),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? AppColors.navy : AppColors.skyBlue,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            AppIconBadge(
              icono: opcion.icono,
              tamano: 56,
              colorFondo: seleccionado ? AppColors.navy : AppColors.skyBlue,
              colorIcono: seleccionado ? AppColors.white : AppColors.navy,
            ),
            const SizedBox(height: 8),
            Text(
              opcion.label,
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
