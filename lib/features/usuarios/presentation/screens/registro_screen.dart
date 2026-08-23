import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/core/utils/politica_contrasena.dart';
import '../../../../shared/widgets/app_checkbox_row.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_icon_badge.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/usuario_providers.dart';
import '../widgets/selector_rol.dart';

/// G01/G02 de HU-01 — registro público como Paciente o Domiciliario (el
/// mockup original ofrecía también Administrador; se quita acá porque la
/// API lo rechaza por diseño — DOCS/context.md, Parte B, sección 4.1). La
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
  bool _aceptaTerminos = false;
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _cargando ? null : () => Navigator.of(context).pop(),
            child: const Text('¿Ya tienes cuenta? Inicia sesión'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppIconBadge(icono: Icons.medical_services_outlined)),
                const SizedBox(height: 16),
                Text(
                  'Crear cuenta',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.navy),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Únete a MediRuta y recibe tus medicamentos sin salir de casa.',
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
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !_cargando,
                  errorText: _errorPassword,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mínimo 8 caracteres, con mayúscula, minúscula, número y símbolo.',
                  style: TextStyle(fontSize: 12, color: AppColors.teal),
                ),
                const SizedBox(height: 16),
                const Text('Selecciona tu rol', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SelectorRol(
                  tipoRegistroSeleccionado: _tipoRegistro,
                  onChanged: (valor) => setState(() => _tipoRegistro = valor),
                ),
                const SizedBox(height: 8),
                AppCheckboxRow(
                  valor: _aceptaTerminos,
                  onChanged: (v) => setState(() => _aceptaTerminos = v),
                  label: const Text(
                    'Acepto los Términos y Condiciones',
                    style: TextStyle(color: AppColors.navy),
                  ),
                ),
                const SizedBox(height: 12),
                AppLoadingButton(
                  label: 'Registrarme',
                  cargando: _cargando,
                  onPressed: _aceptaTerminos ? _registrar : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
