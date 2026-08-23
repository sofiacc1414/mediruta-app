import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_icon_badge.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/usuario_providers.dart';

/// G05 (paso 1) de HU-01 — solicita el OTP de recuperación por correo.
/// La API responde el mismo mensaje exista o no la cuenta (anti-
/// enumeración) — esta pantalla nunca revela si el correo existe.
class RecuperarContrasenaScreen extends ConsumerStatefulWidget {
  const RecuperarContrasenaScreen({super.key});

  static const routeName = '/recuperar-contrasena';

  @override
  ConsumerState<RecuperarContrasenaScreen> createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState
    extends ConsumerState<RecuperarContrasenaScreen> {
  final _correoController = TextEditingController();
  bool _cargando = false;
  String? _error;
  bool _solicitudEnviada = false;

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _solicitar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await ref
          .read(solicitarRecuperacionContrasenaUseCaseProvider)
          .execute(correo: _correoController.text);
      if (!mounted) return;
      setState(() => _solicitudEnviada = true);
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
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: AppIconBadge(
                    icono: _solicitudEnviada ? Icons.mark_email_read_outlined : Icons.key_outlined,
                  ),
                ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  AppErrorBanner(mensaje: _error!),
                  const SizedBox(height: 12),
                ],
                if (_solicitudEnviada) ...[
                  const Text(
                    'Si el correo está registrado, recibirás un código de recuperación.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.teal),
                  ),
                  const SizedBox(height: 16),
                  AppLoadingButton(
                    label: 'Ya tengo el código',
                    cargando: false,
                    onPressed: () => Navigator.of(context).pushReplacementNamed(
                      '/restablecer-contrasena',
                      arguments: _correoController.text,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Ingresa tu correo y te enviaremos un código para restablecer tu contraseña.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.teal),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Correo electrónico',
                    icono: Icons.mail_outline,
                    controller: _correoController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_cargando,
                  ),
                  const SizedBox(height: 20),
                  AppLoadingButton(
                    label: 'Enviar código',
                    cargando: _cargando,
                    onPressed: _solicitar,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
