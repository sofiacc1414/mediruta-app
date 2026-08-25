import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Card compacta de una métrica (Home) — ícono, número grande, label y un
/// delta opcional. El delta usa una flecha + texto para indicar dirección,
/// nunca rojo/verde (DOCS/context.md, Parte A, sección 4): la flecha ya
/// comunica sin necesitar un color fuera de la paleta.
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.icono,
    required this.valor,
    required this.label,
    this.delta,
    this.deltaPositivo = true,
  });

  final IconData icono;
  final String valor;
  final String label;

  /// Ej. "12% vs. ayer" — `null` no muestra la fila de delta.
  final String? delta;
  final bool deltaPositivo;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.beige,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: AppColors.navy, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.teal, fontSize: 12),
          ),
          if (delta != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  deltaPositivo ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: AppColors.navy,
                ),
                const SizedBox(width: 2),
                Text(
                  delta!,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
