import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Input reutilizable con label y estados normal/focus/disabled/error
/// (DOCS/context.md, Parte A, secciones 15 y 23). Estilo *filled* tipo
/// píldora con ícono prefijo, para acercarse al lenguaje visual del
/// mockup. Con `esPassword: true` agrega su propio toggle de mostrar/
/// ocultar contraseña — cada pantalla no repite esa lógica.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.errorText,
    this.esPassword = false,
    this.icono,
    this.keyboardType,
    this.autofillHints,
    this.enabled = true,
    this.onChanged,
    this.focusNode,
  });

  final String label;
  final TextEditingController? controller;
  final String? errorText;
  final bool esPassword;
  final IconData? icono;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  /// Opcional — sin esto, el campo se maneja con un FocusNode propio e
  /// interno (comportamiento normal). Hace falta pasarlo explícitamente
  /// cuando algo externo necesita saber si ESTE campo tiene foco (p.ej.
  /// `RawAutocomplete.fieldViewBuilder`, que decide si mostrar sus
  /// opciones mirando el FocusNode que le pasaste, no el que el campo
  /// use puertas adentro).
  final FocusNode? focusNode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _ocultarTexto = widget.esPassword;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _ocultarTexto,
      keyboardType: widget.keyboardType,
      autofillHints: widget.autofillHints,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        prefixIcon: widget.icono != null
            ? Icon(widget.icono, color: AppColors.teal)
            : null,
        suffixIcon: widget.esPassword
            ? IconButton(
                icon: Icon(
                  _ocultarTexto ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.teal,
                ),
                onPressed: () => setState(() => _ocultarTexto = !_ocultarTexto),
              )
            : null,
        filled: true,
        fillColor: AppColors.beige,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.navy, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }
}
