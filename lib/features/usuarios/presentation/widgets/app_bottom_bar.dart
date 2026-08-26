import 'package:flutter/material.dart';
import '../../../../shared/core/theme/app_colors.dart';

/// Barra de navegación fija de la app — deliberadamente mínima (2
/// acciones, no la típica barra de 4-5 íconos): "Cuenta" agrupa todo lo
/// que no es "qué está pasando ahora" (perfil, modo, mis pedidos,
/// cerrar sesión — ver `AppMenuSheet`), e "Inicio" es el único destino
/// real de la barra en sí, elevado al centro para anclar la
/// composición. Vive solo en `HomeScreen` — el resto de las pantallas
/// sigue con su AppBar + volver normal, esta barra es el punto de
/// entrada a todo, no un tab switcher de varias pantallas.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.onMenuTap, required this.onHomeTap});

  final VoidCallback onMenuTap;
  final VoidCallback onHomeTap;

  static const _alturaBarra = 64.0;
  static const _diametroInicio = 60.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _alturaBarra + _diametroInicio / 2,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: _alturaBarra,
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _BotonBarra(
                    icono: Icons.menu_rounded,
                    etiqueta: 'Cuenta',
                    onTap: onMenuTap,
                  ),
                ),
                const SizedBox(width: _diametroInicio),
                // Espacio simétrico al de "Cuenta" — mantiene el botón
                // de Inicio realmente centrado en vez de corrido hacia
                // la derecha por el ancho del ícono de la izquierda.
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: onHomeTap,
              child: Container(
                width: _diametroInicio,
                height: _diametroInicio,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                  border: Border.all(color: AppColors.navy, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.home_rounded, color: AppColors.navy, size: 28),
              ),
            ),
          ),
        ],
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
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: AppColors.white),
          const SizedBox(height: 2),
          Text(etiqueta, style: const TextStyle(color: AppColors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
