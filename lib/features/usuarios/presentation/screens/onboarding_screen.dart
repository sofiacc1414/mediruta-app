import 'package:flutter/material.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_icon_badge.dart';

/// Pantalla de bienvenida antes del login/registro. No corresponde a
/// ningún criterio Gxx de HU-01 — se agregó a pedido explícito para
/// acercarse al mockup del equipo. Es una sola pantalla estática (el
/// mockup sugiere un carrusel de varios slides con puntos de paginación,
/// pero solo se compartió el contenido del primero).
///
/// Hero navy arriba + sheet blanca redondeada abajo — mismo lenguaje
/// "bloque de color + card" del resto del rediseño (mockups tipo
/// CargoFlow), en vez del fondo plano beige de antes.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onComenzar});

  final VoidCallback onComenzar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: AppIconBadge(
                      icono: Icons.local_shipping_outlined,
                      tamano: 140,
                      colorFondo: AppColors.skyBlue,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // El logo real va acá (fondo blanco) y no en el hero
                      // navy de arriba — el wordmark viene en navy, sobre
                      // navy quedaría invisible.
                      Image.asset(
                        'assets/images/logo_mediruta.png',
                        height: 40,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Tus medicamentos, contigo y a tiempo',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.navy),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Entregas seguras, rápidas y confiables. Cuidamos de ti en cada paso.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.teal),
                      ),
                      const SizedBox(height: 32),
                      AppButton(label: 'Comenzar', onPressed: onComenzar),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
