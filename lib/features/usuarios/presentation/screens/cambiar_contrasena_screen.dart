import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/utils/politica_contrasena.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../providers/usuario_providers.dart';

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

  bool _ocultarActual = true;
  bool _ocultarNueva = true;

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
        SnackBar(
          content: const Text(
            'Contraseña actualizada.',
            style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 4,
        ),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Cambiar contraseña',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: AppColors.navy,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.navy, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.skyBlue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_outlined,
                    color: AppColors.teal,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Ingresa tu contraseña actual y crea una nueva para mantener tu cuenta segura.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                if (_error != null) ...[
                  AppErrorBanner(mensaje: _error!),
                  const SizedBox(height: 12),
                ],

                _CampoContrasena(
                  label: 'Contraseña actual',
                  icono: Icons.lock_outline,
                  controller: _passwordActualController,
                  ocultar: _ocultarActual,
                  onToggleOcultar: () => setState(() => _ocultarActual = !_ocultarActual),
                  enabled: !_cargando,
                ),
                const SizedBox(height: 16),

                _CampoContrasena(
                  label: 'Nueva contraseña',
                  icono: Icons.enhanced_encryption_outlined,
                  controller: _nuevaPasswordController,
                  ocultar: _ocultarNueva,
                  onToggleOcultar: () => setState(() => _ocultarNueva = !_ocultarNueva),
                  enabled: !_cargando,
                  autofillHints: const [AutofillHints.newPassword],
                  errorText: _errorPassword,
                ),

                const SizedBox(height: 24),

                // BOTÓN AZUL DIFUMINADO TIPO "PÍLDORA"
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _cambiar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.skyBlue.withValues(alpha: 0.3), // Azul muy claro difuminado
                      foregroundColor: AppColors.navy, // Letras azul oscuro
                      disabledBackgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Píldora
                      ),
                      elevation: 0,
                    ),
                    child: _cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.navy,
                            ),
                          )
                        : const Text(
                            'Guardar cambios',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

class _CampoContrasena extends StatelessWidget {
  const _CampoContrasena({
    required this.label,
    required this.icono,
    required this.controller,
    required this.ocultar,
    required this.onToggleOcultar,
    required this.enabled,
    this.autofillHints,
    this.errorText,
  });

  final String label;
  final IconData icono;
  final TextEditingController controller;
  final bool ocultar;
  final VoidCallback onToggleOcultar;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: errorText != null
              ? Colors.red.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: ocultar,
        enabled: enabled,
        autofillHints: autofillHints,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.navy,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: errorText != null
                ? Colors.red
                : Colors.grey.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icono,
            color: errorText != null ? Colors.red : AppColors.teal,
            size: 20,
          ),
          suffixIcon: IconButton(
            onPressed: onToggleOcultar,
            icon: Icon(
              ocultar ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey,
              size: 20,
            ),
          ),
          errorText: errorText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.teal, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          ),
        ),
      ),
    );
  }
}