import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/utils/politica_contrasena.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/usuario_providers.dart';
import '../widgets/selector_rol.dart';

/// G01/G02 de HU-01 — registro público como Paciente o Domiciliario. La
/// API no crea sesión al registrar, así que el flujo termina en login.
class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  static const routeName = '/registro';

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  String _tipoRegistro = 'PACIENTE';
  bool _cargando = false;
  String? _error;
  String? _errorPassword;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final errorPassword = PoliticaContrasena.validar(_passwordController.text);
    setState(() {
      _errorPassword = errorPassword;
      _error = null;
    });
    if (errorPassword != null) return;

    setState(() => _cargando = true);
    try {
      await ref
          .read(registrarUsuarioUseCaseProvider)
          .execute(
            correo: _correoController.text,
            password: _passwordController.text,
            tipoRegistro: _tipoRegistro,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada. Ya puedes iniciar sesión.')),
      );
      Navigator.of(context).pop();
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
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  AppErrorBanner(mensaje: _error!),
                  const SizedBox(height: 12),
                ],
                const Text('¿Cómo vas a usar MediRuta?'),
                const SizedBox(height: 8),
                SelectorRol(
                  tipoRegistroSeleccionado: _tipoRegistro,
                  onChanged: (valor) => setState(() => _tipoRegistro = valor),
                ),
                const SizedBox(height: 16),
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
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !_cargando,
                  errorText: _errorPassword,
                ),
                const SizedBox(height: 20),
                AppLoadingButton(
                  label: 'Crear cuenta',
                  cargando: _cargando,
                  onPressed: _registrar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
