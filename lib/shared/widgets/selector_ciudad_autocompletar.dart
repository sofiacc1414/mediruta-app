import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Campo de ciudad con autocompletar, filtrado por el departamento ya
/// elegido — reemplaza el texto libre que dejaba pasar cualquier cosa
/// (lugares, instituciones, typos) en el campo de ciudad del perfil.
/// Mismo estilo visual que `_CampoPerfil`/`_CampoPerfilDropdown` de
/// `perfil_screen.dart` (no son reutilizables desde acá por ser
/// privados a ese archivo, así que se replica el mismo look).
class SelectorCiudadAutocompletar extends StatelessWidget {
  const SelectorCiudadAutocompletar({
    super.key,
    required this.label,
    required this.icono,
    required this.opciones,
    required this.valorInicial,
    required this.enabled,
    required this.onSeleccionar,
  });

  final String label;
  final IconData icono;
  final List<String> opciones;
  final String valorInicial;
  final bool enabled;
  final void Function(String) onSeleccionar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: valorInicial),
        optionsBuilder: (textEditingValue) {
          if (!enabled) return const Iterable<String>.empty();
          final consulta = textEditingValue.text.trim().toLowerCase();
          if (consulta.isEmpty) return opciones;
          return opciones.where(
            (ciudad) => ciudad.toLowerCase().contains(consulta),
          );
        },
        onSelected: onSeleccionar,
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220, minWidth: 260),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final opcion = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(
                        opcion,
                        style: const TextStyle(fontSize: 14, color: AppColors.navy),
                      ),
                      onTap: () => onSelected(opcion),
                    );
                  },
                ),
              ),
            ),
          );
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            // Solo se puede escoger de la lista — al perder el foco sin
            // una selección válida, se limpia en vez de dejar pasar un
            // texto libre a medio escribir como si fuera la ciudad.
            onEditingComplete: () {
              if (!opciones.contains(controller.text)) {
                controller.clear();
              }
              onSubmitted();
            },
            style: const TextStyle(fontSize: 15, color: AppColors.navy),
            decoration: InputDecoration(
              labelText: label,
              hintText: 'Escribí para buscar…',
              labelStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(icono, color: AppColors.teal, size: 20),
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
          );
        },
      ),
    );
  }
}
