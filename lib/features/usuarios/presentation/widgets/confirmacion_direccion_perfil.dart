import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_colors.dart';
import '../../domain/entities/verificacion_direccion.dart';

/// Confirmación de qué entendió la geocodificación de la dirección del
/// perfil — mismo patrón visual que `MensajeConfirmacionDireccion` de
/// `solicitudes` (no se reusa esa clase a propósito: usa
/// `CandidatoDireccion` de `solicitudes`, y este widget vive en
/// `usuarios` con su propio modelo — ver `verificacion_direccion.dart`).
/// Ronda 12 — bug real reportado: la dirección del perfil recién se
/// validaba al tocar "Guardar cambios", sin loader ni sugerencias
/// mientras tanto.
class MensajeConfirmacionDireccionPerfil extends StatelessWidget {
  const MensajeConfirmacionDireccionPerfil({
    super.key,
    required this.cargando,
    required this.resuelta,
    required this.precisa,
    required this.fallo,
    this.candidatos = const [],
    this.onVerAlternativas,
  });

  final bool cargando;
  final String? resuelta;
  final bool precisa;
  final bool fallo;
  final List<CandidatoDireccionPerfil> candidatos;
  final VoidCallback? onVerAlternativas;

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return _fila(icono: Icons.search, texto: 'Verificando dirección…', relleno: false);
    }
    if (fallo) {
      return _fila(
        icono: Icons.location_off_outlined,
        texto: 'No pudimos ubicar esta dirección — revisala antes de guardar.',
        relleno: true,
      );
    }
    if (resuelta == null) {
      return const SizedBox.shrink();
    }
    if (!precisa) {
      return _fila(
        icono: Icons.info_outline,
        texto:
            '$resuelta — es un lugar grande, agregá más detalle si podés (bloque, portería, entrada).',
        relleno: true,
        enlace: candidatos.isNotEmpty ? '¿No es acá? Elegí otra dirección' : null,
        onEnlace: candidatos.isNotEmpty ? onVerAlternativas : null,
      );
    }
    return _fila(icono: Icons.check_circle_outline, texto: resuelta!, relleno: false);
  }

  Widget _fila({
    required IconData icono,
    required String texto,
    required bool relleno,
    String? enlace,
    VoidCallback? onEnlace,
  }) {
    final fila = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 14, color: AppColors.navy),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                texto,
                style: const TextStyle(color: AppColors.navy, fontSize: 12, height: 1.3),
              ),
              if (enlace != null)
                InkWell(
                  onTap: onEnlace,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      enlace,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    if (!relleno) {
      return Padding(padding: const EdgeInsets.only(left: 14, right: 8, top: 6), child: fila);
    }
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.skyBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.18)),
      ),
      child: fila,
    );
  }
}

/// Modal para elegir entre los candidatos alternos que Nominatim
/// devolvió — mismo patrón que `mostrarSelectorDireccion` de
/// `solicitudes`.
Future<CandidatoDireccionPerfil?> mostrarSelectorDireccionPerfil(
  BuildContext context, {
  required List<CandidatoDireccionPerfil> candidatos,
}) {
  return showModalBottomSheet<CandidatoDireccionPerfil>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Elegí la dirección correcta',
                style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Encontramos varias coincidencias — elegí la que corresponde.',
                style: TextStyle(color: AppColors.teal, fontSize: 13),
              ),
              const SizedBox(height: 12),
              for (final candidato in candidatos)
                InkWell(
                  onTap: () => Navigator.of(context).pop(candidato),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          candidato.precisa ? Icons.check_circle_outline : Icons.info_outline,
                          size: 16,
                          color: AppColors.navy,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            candidato.direccionResuelta,
                            style: const TextStyle(color: AppColors.navy, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ninguna — seguir con la escrita', style: TextStyle(color: AppColors.teal)),
              ),
            ],
          ),
        ),
      );
    },
  );
}
