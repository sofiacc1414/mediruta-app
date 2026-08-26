import 'package:flutter/material.dart';
import '../../../../shared/core/theme/app_colors.dart';

/// Un destino directo de la barra — cada uno navega derecho a su
/// pantalla al primer toque (nada de sub-menús).
class AppBottomNavAction {
  const AppBottomNavAction({required this.icono, required this.etiqueta, required this.onTap});

  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
}

/// Barra de navegación fija — persistente en toda la app (cada
/// Scaffold de las pantallas principales la incluye vía
/// `MainBottomBar`), no solo en Home. "Inicio" es un botón más de la
/// fila, con el mismo peso visual que el resto (sin elevarse ni
/// resaltar) — la lista de `items` la arma quien construye la barra,
/// en el orden en que quiere que aparezcan (típicamente con Inicio en
/// el medio).
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.items});

  final List<AppBottomNavAction> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final item in items)
              _BotonBarra(icono: item.icono, etiqueta: item.etiqueta, onTap: item.onTap),
          ],
        ),
      ),
    );
  }
}

class _BotonBarra extends StatelessWidget {
  const _BotonBarra({required this.icono, required this.etiqueta, required this.onTap});

  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, color: AppColors.white),
              const SizedBox(height: 2),
              Text(
                etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.white, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
