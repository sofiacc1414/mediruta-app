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

/// Barra de navegación fija — persistente en toda la app.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.items});

  final List<AppBottomNavAction> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          // Fondo azul medio suave
          color: const Color(0xFFD6E8F7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          // Borde delgado gris en todo el contorno
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
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
              Icon(icono, color: AppColors.navy),
              const SizedBox(height: 2),
              Text(
                etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.navy, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}