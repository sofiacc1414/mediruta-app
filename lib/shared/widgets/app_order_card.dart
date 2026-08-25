import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'app_status_pill.dart';

/// Fila de un pedido — reusada en "Mis solicitudes" (Paciente) y "Pedidos
/// disponibles" (Domiciliario): mismo lenguaje visual (card con sombra
/// suave, `AppStatusPill` a la derecha), cada pantalla decide qué mostrar
/// como `subtitulo` (fecha vs. distancia) y si hay `estado` para pintar.
class AppOrderCard extends StatelessWidget {
  const AppOrderCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.estado,
    this.trailing,
    this.onTap,
  });

  final String titulo;
  final String subtitulo;
  final String? estado;

  /// Reemplaza el `AppStatusPill` de la derecha cuando la fila necesita
  /// otra cosa ahí (ej. un botón "Aceptar" en el pool del Domiciliario).
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: const TextStyle(color: AppColors.teal, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (trailing != null)
              trailing!
            else if (estado != null)
              AppStatusPill(estado: estado!)
            else
              const Icon(Icons.chevron_right, color: AppColors.navy),
          ],
        ),
      ),
    );
  }
}
