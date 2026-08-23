import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tema oficial (DOCS/context.md, Parte A, secciones 6-8).
///
/// NOTA sobre tipografía de títulos: "Times New Roman MT Condensed" es una
/// fuente propietaria de Microsoft, no disponible en Google Fonts ni
/// distribuible libremente. Mientras el equipo no agregue el archivo .ttf
/// real bajo `assets/fonts/` (con la licencia correspondiente) y lo declare
/// en `pubspec.yaml`, se usa un serif condensado del sistema como fallback
/// — ver `_headingFallback`. NO reemplaces esto por otra fuente "parecida"
/// sin discutirlo en equipo (Parte A, sección 6).
final _headingFallback = const TextStyle(
  fontFamily: 'Georgia',
  fontFamilyFallback: ['Times New Roman', 'serif'],
);

ThemeData buildAppTheme() {
  final bodyTextTheme = GoogleFonts.poppinsTextTheme();

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.white,
    colorScheme: const ColorScheme.light(
      primary: AppColors.navy,
      secondary: AppColors.teal,
      surface: AppColors.white,
      surfaceContainerHighest: AppColors.skyBlue,
      surfaceContainer: AppColors.beige,
      // Sin rojo de error por defecto de Material (DOCS/context.md, Parte A,
      // sección 4 — nunca colores automáticos del framework ni fuera de la
      // paleta, ni siquiera para error/advertencia/éxito).
      error: AppColors.navy,
      onError: AppColors.white,
    ),
    textTheme: bodyTextTheme.copyWith(
      headlineLarge: bodyTextTheme.headlineLarge?.merge(_headingFallback),
      headlineMedium: bodyTextTheme.headlineMedium?.merge(_headingFallback),
      headlineSmall: bodyTextTheme.headlineSmall?.merge(_headingFallback),
      titleLarge: bodyTextTheme.titleLarge?.merge(_headingFallback),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: AppColors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
      ),
    ),
  );
}
