import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/utils/politica_contrasena.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_icon_badge.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/usuario_providers.dart';

/// G06 de HU-01 — cambio de contraseña con sesión activa. La API mantiene
/// la sesión actual y revoca las demás (context.md, sección "G05 vs G06").
class CambiarContrasenaScreen extends ConsumerStatefulWidget {
  const CambiarContrasenaScreen({super.key});

  static const routeName = '/cambiar-contrasena';

  @override
  ConsumerState<CambiarContrasenaScreen> createState() =>
      _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState
    extends ConsumerState<CambiarContrasenaScreen> {
  final _passwordActualController = TextEditingController();
  final _nuevaPasswordController = TextEditingController();
  bool _cargando = false;
  String? _error;
  String? _errorPassword;

  @override
  void dispose() {
    _passwordActualController.dispose();
    _nuevaPasswordController.dispose();
    super.dispose();
  }

  Future<void> _cambiar() async {
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
          .read(cambiarContrasenaUseCaseProvider)
          .execute(
            passwordActual: _passwordActualController.text,
            nuevaPassword: _nuevaPasswordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada.')),
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
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppIconBadge(icono: Icons.lock_reset_outlined)),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  AppErrorBanner(mensaje: _error!),
                  const SizedBox(height: 12),
                ],
                AppTextField(
                  label: 'Contraseña actual',
                  icono: Icons.lock_outline,
                  esPassword: true,
                  controller: _passwordActualController,
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
                  label: 'Guardar cambios',
                  cargando: _cargando,
                  onPressed: _cambiar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
