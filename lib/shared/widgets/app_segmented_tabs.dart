import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Control tipo píldora para filtros/tabs (ej. Activas/Historial en "Mis
/// solicitudes", el selector de "Modo" en Home) — fill navy en el
/// seleccionado, resto texto navy sobre skyBlue.
class AppSegmentedTabs extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.opciones,
    required this.seleccionado,
    required this.onSeleccionar,
  });

  final List<String> opciones;
  final int seleccionado;
  final ValueChanged<int> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.skyBlue.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (var i = 0; i < opciones.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSeleccionar(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == seleccionado ? AppColors.navy : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    opciones[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: i == seleccionado ? AppColors.white : AppColors.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
