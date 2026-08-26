import 'package:flutter/material.dart';
import '../../../../shared/core/theme/app_colors.dart';

/// Un destino directo de la barra — a diferencia de la v3 (un botón
/// "Cuenta" que abría un menú con todo adentro), cada uno de estos
/// navega directo a su pantalla al primer toque.
class AppBottomNavAction {
  const AppBottomNavAction({required this.icono, required this.etiqueta, required this.onTap});

  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
}

/// Barra de navegación fija de la app — "Inicio" elevado al centro
/// (siempre visible, ancla la composición); a los lados, destinos
/// directos que varían según el rol activo (ej. el Domiciliario suma
/// "Pedidos disponibles" mientras está en línea, algo que el Paciente
/// nunca ve). Vive solo en `HomeScreen`; el resto de las pantallas
/// sigue con su AppBar + volver normal.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.onHomeTap,
    this.leftItems = const [],
    this.rightItems = const [],
  });

  final VoidCallback onHomeTap;
  final List<AppBottomNavAction> leftItems;
  final List<AppBottomNavAction> rightItems;

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
                Expanded(child: _GrupoBotones(items: leftItems)),
                const SizedBox(width: _diametroInicio),
                Expanded(child: _GrupoBotones(items: rightItems)),
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

class _GrupoBotones extends StatelessWidget {
  const _GrupoBotones({required this.items});

  final List<AppBottomNavAction> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final item in items)
          _BotonBarra(icono: item.icono, etiqueta: item.etiqueta, onTap: item.onTap),
      ],
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: AppColors.white),
            const SizedBox(height: 2),
            Text(
              etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
