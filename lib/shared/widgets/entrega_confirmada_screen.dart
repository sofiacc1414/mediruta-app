import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/usuarios/presentation/screens/home_screen.dart';
import '../core/theme/app_colors.dart';
import 'app_button.dart';

/// Pantalla completa que cierra el ciclo de un pedido — la reemplaza el
/// SnackBar "Entrega confirmada con éxito" que antes se veía apenas un
/// instante y desaparecía. La ven tanto el Paciente (cuando su pedido
/// pasa a "entregado" mientras tiene el detalle abierto —
/// `SolicitudDetalleScreen` la dispara sola al detectar la transición)
/// como el Domiciliario (al confirmar la entrega con el código,
/// `MiPedidoActivoScreen` la empuja directo después de esa acción).
class EntregaConfirmadaScreen extends StatelessWidget {
  const EntregaConfirmadaScreen({
    super.key,
    required this.mensaje,
    this.codigoPedido,
  });

  /// Texto específico del rol — ver los dos puntos de uso.
  final String mensaje;
  final String? codigoPedido;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.beige,
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.teal, AppColors.navy],
                    ),
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
                ),
                const SizedBox(height: 28),
                Text(
                  '¡Pedido entregado!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                if (codigoPedido != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    codigoPedido!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    height: 1.5,
                    color: AppColors.navy.withValues(alpha: 0.72),
                  ),
                ),
                const Spacer(),
                AppButton(
                  label: 'Volver al inicio',
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil(HomeScreen.routeName, (route) => false),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
