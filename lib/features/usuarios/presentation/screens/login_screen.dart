import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_banner.dart';
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
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'MediRuta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  AppErrorBanner(mensaje: _error!),
                  const SizedBox(height: 12),
                ],
                AppTextField(
                  label: 'Correo',
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !_cargando,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Contraseña',
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  enabled: !_cargando,
                ),
                const SizedBox(height: 20),
                AppLoadingButton(
                  label: 'Ingresar',
                  cargando: _cargando,
                  onPressed: _iniciarSesion,
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Olvidé mi contraseña',
                  variante: AppButtonVariante.secondary,
                  onPressed: _cargando
                      ? null
                      : () => Navigator.of(context).pushNamed('/recuperar-contrasena'),
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Crear una cuenta',
                  variante: AppButtonVariante.secondary,
                  onPressed: _cargando
                      ? null
                      : () => Navigator.of(context).pushNamed('/registro'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
