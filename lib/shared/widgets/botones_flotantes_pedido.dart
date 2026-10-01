import 'package:flutter/material.dart';

import '../../features/chat/presentation/chat_screen.dart';
import '../../features/tracking/presentation/seguimiento_mapa_screen.dart';
import '../core/theme/app_colors.dart';

/// Accesos rápidos a chat y seguimiento en vivo — flotantes, centrados
/// verticalmente sobre el borde derecho de la pantalla (pedido
/// explícito: antes vivían como íconos del AppBar, uno por feature,
/// compitiendo por el mismo espacio angosto). Usar dentro de un
/// `Stack` que envuelva el body de la pantalla.
class BotonesFlotantesPedido extends StatelessWidget {
  const BotonesFlotantesPedido({
    super.key,
    required this.solicitudId,
    this.mostrarChat = false,
    this.mostrarSeguimiento = false,
  });

  final String solicitudId;
  final bool mostrarChat;
  final bool mostrarSeguimiento;

  @override
  Widget build(BuildContext context) {
    if (!mostrarChat && !mostrarSeguimiento) return const SizedBox.shrink();
    return Positioned(
      right: 14,
      top: MediaQuery.of(context).size.height * 0.4,
      child: Column(
        children: [
          if (mostrarSeguimiento)
            _BotonFlotante(
              icono: Icons.map_outlined,
              tooltip: 'Seguimiento en vivo',
              onPressed: () => Navigator.pushNamed(
                context,
                SeguimientoMapaScreen.routeName,
                arguments: solicitudId,
              ),
            ),
          if (mostrarSeguimiento && mostrarChat) const SizedBox(height: 14),
          if (mostrarChat)
            _BotonFlotante(
              icono: Icons.chat_bubble_outline_rounded,
              tooltip: 'Chat',
              onPressed: () => Navigator.pushNamed(
                context,
                ChatScreen.routeName,
                arguments: solicitudId,
              ),
            ),
        ],
      ),
    );
  }
}

class _BotonFlotante extends StatelessWidget {
  const _BotonFlotante({required this.icono, required this.tooltip, required this.onPressed});

  final IconData icono;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.navy,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: AppColors.navy.withValues(alpha: 0.4),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icono, color: AppColors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
