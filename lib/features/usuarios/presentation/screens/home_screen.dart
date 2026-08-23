import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_icon_badge.dart';
import '../../../../shared/widgets/app_selection_card.dart';
import '../../../solicitudes/presentation/screens/mis_solicitudes_screen.dart';
import '../../domain/entities/rol_asignado.dart';
import '../providers/auth_session_provider.dart';

/// Placeholder post-login — todavía no hay más historias implementadas
/// (solicitudes/documentos/entregas). Sirve para probar G06/G07 desde una
/// sesión real, y para elegir el "modo" Paciente/Domiciliario cuando la
/// cuenta tiene ambos roles (context.md, Parte B, sección 4.1: la
/// selección de modo es solo una decisión de presentación — la API
/// siempre determina los permisos reales consultando `usuario_roles`, no
/// lo que se elija acá). Se reemplaza cuando se implementen las
/// pantallas reales de cada rol.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  static const _etiquetas = {'PACIENTE': 'Paciente', 'DOMICILIARIO': 'Domiciliario'};
  static const _iconos = {
    'PACIENTE': Icons.person_outline,
    'DOMICILIARIO': Icons.moped_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(authSessionProvider);
    final usuario = estado is AuthAutenticado ? estado.usuario : null;
    final roles = usuario?.roles ?? const <RolAsignado>[];

    // Por defecto, el modo activo es el primer rol de la cuenta — vive en
    // `modoActivoProvider` (no como estado local de esta pantalla) para
    // que se mantenga al navegar a otras pantallas, ej. `PerfilScreen`,
    // que también deben respetar el modo elegido acá.
    final modo = ref.watch(modoActivoProvider) ?? (roles.isNotEmpty ? roles.first.codigo : null);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppIconBadge(icono: Icons.check_circle_outline)),
                const SizedBox(height: 20),
                Text(
                  usuario != null ? 'Hola, ${usuario.correo}' : 'Sesión activa',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.navy),
                  textAlign: TextAlign.center,
                ),
                if (roles.length > 1) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Modo',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final rol in roles) ...[
                        Expanded(
                          child: AppSelectionCard(
                            icono: _iconos[rol.codigo] ?? Icons.person_outline,
                            label: _etiquetas[rol.codigo] ?? rol.codigo,
                            sublabel: rol.estado == 'habilitado' ? null : 'Pendiente de validación',
                            seleccionado: modo == rol.codigo,
                            onTap: () =>
                                ref.read(modoActivoProvider.notifier).state = rol.codigo,
                          ),
                        ),
                        if (rol != roles.last) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ] else if (roles.length == 1) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Rol: ${_etiquetas[roles.first.codigo] ?? roles.first.codigo}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.teal),
                  ),
                ],
                const SizedBox(height: 28),
                if (modo == 'PACIENTE') ...[
                  AppButton(
                    label: 'Mis solicitudes',
                    onPressed: () =>
                        Navigator.of(context).pushNamed(MisSolicitudesScreen.routeName),
                  ),
                  const SizedBox(height: 8),
                ],
                AppButton(
                  label: 'Mi perfil',
                  onPressed: () => Navigator.of(context).pushNamed('/perfil'),
                ),
                const SizedBox(height: 8),
                AppButton(
                  variante: AppButtonVariante.secondary,
                  label: 'Cambiar contraseña',
                  onPressed: () => Navigator.of(context).pushNamed('/cambiar-contrasena'),
                ),
                const SizedBox(height: 8),
                AppButton(
                  variante: AppButtonVariante.secondary,
                  onPressed: () async {
                    await ref.read(authSessionProvider.notifier).cerrarSesion();
                    ref.invalidate(modoActivoProvider);
                    if (context.mounted) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (_) => false);
                    }
                  },
                  label: 'Cerrar sesión',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
