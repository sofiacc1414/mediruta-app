import 'package:flutter/material.dart';
import 'app_button.dart';

/// AppButton con estado de carga: deshabilita el botón y muestra un
/// spinner en vez del label mientras `cargando` es true, para evitar
/// doble submit (DOCS/context.md, Parte A, sección 19 — feedback de
/// loading obligatorio).
class AppLoadingButton extends StatelessWidget {
  const AppLoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.cargando,
    this.variante = AppButtonVariante.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool cargando;
  final AppButtonVariante variante;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: cargando ? 'Cargando…' : label,
      onPressed: cargando ? null : onPressed,
      variante: variante,
    );
  }
}
