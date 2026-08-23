import 'package:flutter/material.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_icon_badge.dart';

/// Pantalla de bienvenida antes del login/registro. No corresponde a
/// ningún criterio Gxx de HU-01 — se agregó a pedido explícito para
/// acercarse al mockup del equipo. Es una sola pantalla estática (el
/// mockup sugiere un carrusel de varios slides con puntos de paginación,
/// pero solo se compartió el contenido del primero).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onComenzar});

  final VoidCallback onComenzar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppIconBadge(
                    icono: Icons.local_shipping_outlined,
                    tamano: 140,
                    colorFondo: AppColors.skyBlue,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'MediRuta',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 40),
                  AppButton(label: 'Comenzar', onPressed: onComenzar),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
