import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/core/theme/modo_oscuro_provider.dart';
import '../../../../shared/core/theme/modo_alto_contraste_provider.dart';

/// Un destino directo de la barra — cada uno navega derecho a su
/// pantalla al primer toque (nada de sub-menús).
class AppBottomNavAction {
  const AppBottomNavAction({required this.icono, required this.etiqueta, required this.onTap});

  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
}

/// Barra de navegación fija — persistente en toda la app. `ConsumerWidget`
/// (no `StatelessWidget`) solo para que el `watch` fuerce el repintado
/// cuando cambia modo oscuro/alto contraste desde Perfil mientras esta
/// barra sigue montada en otra pantalla — `AppColors` ya refleja el
/// estado actual sin BuildContext, pero sin un `watch` acá este widget
/// no se reconstruye solo.
class AppBottomNavBar extends ConsumerWidget {
  const AppBottomNavBar({super.key, required this.items});

  final List<AppBottomNavAction> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(modoOscuroProvider);
    ref.watch(modoAltoContrasteProvider);
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          // Fondo azul medio suave en claro; gris en oscuro (CA: "cambiar
          // su color a gris en modo oscuro") — un tono distinto de
          // `AppColors.white` para que la barra se distinga de las
          // tarjetas de contenido.
          color: AppColors.modoOscuro ? const Color(0xFF3A3A3A) : const Color(0xFFD6E8F7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
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
                style: TextStyle(color: AppColors.navy, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}