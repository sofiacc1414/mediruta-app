import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

/// Aviso de formulario para el flujo de autenticación.
///
/// [compact] = mensaje asociado a un campo (debajo del input).
/// El resto = aviso general del formulario (API, conexión, etc.).
/// Paleta oficial únicamente (Parte A, secciones 3-4).
class AppFormNotice extends StatelessWidget {
  const AppFormNotice({
    super.key,
    required this.mensaje,
    this.compact = false,
  });

  final String mensaje;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final texto = Text(
      mensaje,
      softWrap: true,
      style: GoogleFonts.poppins(
        color: AppColors.navy,
        fontSize: compact ? 11.5 : 12.5,
        fontWeight: compact ? FontWeight.w400 : FontWeight.w500,
        height: 1.35,
      ),
    );

    final fila = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          color: AppColors.navy,
          size: compact ? 14 : 18,
        ),
        SizedBox(width: compact ? 6 : 8),
        Expanded(child: texto),
      ],
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(left: 14, right: 8, top: 6),
        child: fila,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.skyBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: fila,
      ),
    );
  }
}
