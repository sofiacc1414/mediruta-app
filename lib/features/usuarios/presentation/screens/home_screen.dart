import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_icon_badge.dart';
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
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _modo;

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(authSessionProvider);
    final usuario = estado is AuthAutenticado ? estado.usuario : null;
    final roles = usuario?.roles ?? const <RolAsignado>[];

    // Por defecto, el modo activo es el primer rol de la cuenta. No se
    // persiste entre sesiones — cada login vuelve a arrancar en el rol
    // por defecto (mismo alcance simplificado que el onboarding).
    if (_modo == null && roles.isNotEmpty) {
      _modo = roles.first.codigo;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('MediRuta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIconBadge(icono: Icons.check_circle_outline),
                const SizedBox(height: 16),
                Text(
                  usuario != null ? 'Hola, ${usuario.correo}' : 'Sesión activa',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (roles.length > 1) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Modo',
                    style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _SelectorModo(
                    roles: roles,
                    modoSeleccionado: _modo!,
                    onChanged: (codigo) => setState(() => _modo = codigo),
                  ),
                ] else if (roles.length == 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Rol: ${roles.first.codigo.toLowerCase()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.teal),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  label: 'Cambiar contraseña',
                  onPressed: () => Navigator.of(context).pushNamed('/cambiar-contrasena'),
                ),
                const SizedBox(height: 8),
                AppButton(
                  variante: AppButtonVariante.secondary,
                  onPressed: () async {
                    await ref.read(authSessionProvider.notifier).cerrarSesion();
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

/// Chips "Paciente" / "Domiciliario" — marca "pendiente de validación"
/// cuando el rol todavía no está `habilitado` (HU-08, aún no implementada:
/// un Domiciliario recién registrado ve su solicitud pendiente, no se le
/// oculta el modo).
class _SelectorModo extends StatelessWidget {
  const _SelectorModo({
    required this.roles,
    required this.modoSeleccionado,
    required this.onChanged,
  });

  final List<RolAsignado> roles;
  final String modoSeleccionado;
  final ValueChanged<String> onChanged;

  static const _etiquetas = {'PACIENTE': 'Paciente', 'DOMICILIARIO': 'Domiciliario'};

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final rol in roles)
          ChoiceChip(
            label: Text(
              rol.estado == 'habilitado'
                  ? (_etiquetas[rol.codigo] ?? rol.codigo)
                  : '${_etiquetas[rol.codigo] ?? rol.codigo} (pendiente)',
            ),
            selected: modoSeleccionado == rol.codigo,
            onSelected: (_) => onChanged(rol.codigo),
            selectedColor: AppColors.navy,
            labelStyle: TextStyle(
              color: modoSeleccionado == rol.codigo ? AppColors.white : AppColors.navy,
            ),
            backgroundColor: AppColors.skyBlue,
          ),
      ],
    );
  }
}
