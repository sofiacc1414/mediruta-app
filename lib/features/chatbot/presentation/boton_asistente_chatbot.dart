import 'package:flutter/material.dart';

import '../../../shared/core/theme/app_colors.dart';
import 'chatbot_screen.dart';

/// Acceso flotante al chatbot — pensado para pantallas SIN sesión
/// (onboarding, login) donde igual hace falta resolver dudas de
/// registro o de contraseña (pedido explícito: el asistente debe
/// estar disponible desde el inicio, no solo una vez logueado). En
/// Home el acceso va en el encabezado, no acá — ver `_Encabezado`.
class BotonAsistenteChatbot extends StatelessWidget {
  const BotonAsistenteChatbot({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            color: AppColors.white.withValues(alpha: 0.85),
            shape: const CircleBorder(),
            elevation: 2,
            child: IconButton(
              tooltip: 'Asistente MediRuta',
              icon: const Icon(Icons.support_agent_outlined, color: AppColors.navy),
              onPressed: () => Navigator.of(context).pushNamed(ChatbotScreen.routeName),
            ),
          ),
        ),
      ),
    );
  }
}
