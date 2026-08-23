import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/core/utils/politica_contrasena.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_icon_badge.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/usuario_providers.dart';

/// G05 (paso 2) de HU-01 — consume el OTP y fija una nueva contraseña.
/// Recibe el correo como argumento de ruta desde `recuperar_contrasena_screen`.
class RestablecerContrasenaScreen extends ConsumerStatefulWidget {
  const RestablecerContrasenaScreen({super.key, required this.correo});

  static const routeName = '/restablecer-contrasena';

  final String correo;

  @override
  ConsumerState<RestablecerContrasenaScreen> createState() =>
      _RestablecerContrasenaScreenState();
}

class _RestablecerContrasenaScreenState
    extends ConsumerState<RestablecerContrasenaScreen> {
  final _codigoController = TextEditingController();
  final _nuevaPasswordController = TextEditingController();
  bool _cargando = false;
  String? _error;
  String? _errorPassword;

  @override
  void dispose() {
    _codigoController.dispose();
    _nuevaPasswordController.dispose();
    super.dispose();
  }

  Future<void> _restablecer() async {
    final errorPassword = PoliticaContrasena.validar(
      _nuevaPasswordController.text,
    );
    setState(() {
      _errorPassword = errorPassword;
      _error = null;
    });
    if (errorPassword != null) return;

    setState(() => _cargando = true);
    try {
      await ref
          .read(restablecerContrasenaUseCaseProvider)
          .execute(
            correo: widget.correo,
            codigo: _codigoController.text,
            nuevaPassword: _nuevaPasswordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada. Inicia sesión de nuevo.')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
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
      appBar: AppBar(title: const Text('Restablecer contraseña')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppIconBadge(icono: Icons.mark_email_read_outlined)),
                const SizedBox(height: 16),
                Text(
                  'Código enviado a ${widget.correo}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.teal),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  AppErrorBanner(mensaje: _error!),
                  const SizedBox(height: 12),
                ],
                AppTextField(
                  label: 'Código de 6 dígitos',
                  icono: Icons.pin_outlined,
                  controller: _codigoController,
                  keyboardType: TextInputType.number,
                  enabled: !_cargando,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Nueva contraseña',
                  icono: Icons.lock_outline,
                  esPassword: true,
                  controller: _nuevaPasswordController,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !_cargando,
                  errorText: _errorPassword,
                ),
                const SizedBox(height: 20),
                AppLoadingButton(
                  label: 'Restablecer contraseña',
                  cargando: _cargando,
                  onPressed: _restablecer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
