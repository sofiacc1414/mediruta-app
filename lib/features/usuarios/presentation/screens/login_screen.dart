import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_checkbox_row.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_icon_badge.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_session_provider.dart';
import '../providers/usuario_providers.dart';

/// G03/G04 de HU-01 — inicio de sesión.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false;
  bool _recordarme = true;
  String? _error;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final usuario = await ref
          .read(iniciarSesionUseCaseProvider)
          .execute(
            correo: _correoController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      ref.read(authSessionProvider.notifier).sesionIniciada(usuario);
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppIconBadge(icono: Icons.lock_outline)),
                const SizedBox(height: 20),
                Text(
                  'Iniciar sesión',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.navy),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bienvenido de nuevo a MediRuta',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.teal),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  AppErrorBanner(mensaje: _error!),
                  const SizedBox(height: 12),
                ],
                AppTextField(
                  label: 'Correo electrónico',
                  icono: Icons.mail_outline,
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !_cargando,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Contraseña',
                  icono: Icons.lock_outline,
                  esPassword: true,
                  controller: _passwordController,
                  autofillHints: const [AutofillHints.password],
                  enabled: !_cargando,
                ),
                AppCheckboxRow(
                  valor: _recordarme,
                  onChanged: (v) => setState(() => _recordarme = v),
                  label: const Text('Recordarme', style: TextStyle(color: AppColors.navy)),
                ),
                const SizedBox(height: 8),
                AppLoadingButton(
                  label: 'Entrar',
                  cargando: _cargando,
                  onPressed: _iniciarSesion,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _cargando
                        ? null
                        : () => Navigator.of(context).pushNamed('/recuperar-contrasena'),
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Expanded(child: Divider(color: AppColors.skyBlue)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('o continúa con', style: TextStyle(color: AppColors.teal, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: AppColors.skyBlue)),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: IconButton.filled(
                    // Biometría no implementada: requiere el paquete
                    // local_auth + configuración nativa por plataforma y
                    // su propio diseño de seguridad — fuera de alcance de
                    // HU-01. Se deja visible (deshabilitado) para no
                    // fingir una función que no existe.
                    onPressed: null,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.skyBlue,
                      disabledBackgroundColor: AppColors.skyBlue,
                    ),
                    icon: const Icon(Icons.fingerprint, color: AppColors.navy),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _cargando
                        ? null
                        : () => Navigator.of(context).pushNamed('/registro'),
                    child: const Text('¿No tienes cuenta? Crear una cuenta'),
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
