import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/core/theme/modo_alto_contraste_provider.dart';
import '../../../../shared/core/theme/modo_oscuro_provider.dart';
import '../../../../shared/widgets/app_button.dart';

/// Módulo 4 — cuando el pedido se paga en efectivo, el código de
/// entrega no finaliza la transacción directo: abre esta pantalla para
/// que el Domiciliario confirme que recibió el dinero antes de cerrar
/// el pedido (ver spec: "el código para finalizar debe abrir la
/// pantalla de cobro del domiciliario y cerrar la transacción si es en
/// efectivo"). Devuelve `true` por `Navigator.pop` si confirma, o
/// `false`/`null` si cancela (el pedido sigue activo, puede reintentar).
class CobroEfectivoScreen extends ConsumerWidget {
  const CobroEfectivoScreen({
    super.key,
    required this.montoACobrar,
    this.codigoPedido,
  });

  final double montoACobrar;
  final String? codigoPedido;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(modoOscuroProvider);
    ref.watch(modoAltoContrasteProvider);
    final monto = montoACobrar.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        backgroundColor: AppColors.beige,
        elevation: 0,
        title: const Text('Cobro en efectivo'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.teal, AppColors.navy],
                  ),
                ),
                child: const Icon(Icons.payments_outlined, color: Colors.white, size: 52),
              ),
              const SizedBox(height: 28),
              if (codigoPedido != null)
                Text(
                  codigoPedido!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal,
                    letterSpacing: 0.4,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                'Cobrá al paciente',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$$monto',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Confirmá solo cuando ya hayas recibido el dinero en mano. '
                'Esto cierra el pedido como entregado.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.navy.withValues(alpha: 0.65),
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Ya cobré, finalizar entrega',
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Cancelar',
                variante: AppButtonVariante.secondary,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
