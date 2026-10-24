import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mediruta_app/shared/core/theme/app_colors.dart';

void main() {
  // `AppColors` guarda su estado en estáticos globales — se resetea
  // antes/después de cada test para no filtrar configuración entre
  // tests (orden de ejecución no garantizado).
  setUp(() => AppColors.configurar(oscuro: false, altoContraste: false));
  tearDown(() => AppColors.configurar(oscuro: false, altoContraste: false));

  test('claro + normal usa la paleta oficial histórica', () {
    AppColors.configurar(oscuro: false, altoContraste: false);

    expect(AppColors.navy, const Color(0xFF2F4156));
    expect(AppColors.teal, const Color(0xFF567C8D));
    expect(AppColors.skyBlue, const Color(0xFFC8D9E6));
    expect(AppColors.beige, const Color(0xFFF5EFEB));
    expect(AppColors.white, const Color(0xFFFFFFFF));
    // El Scaffold siempre fue blanco puro (no beige) — esto no puede
    // cambiar nunca en modo claro normal, es como estaba diseñada la
    // app antes de que existiera modo oscuro/alto contraste.
    expect(AppColors.fondoPagina, const Color(0xFFFFFFFF));
    expect(AppColors.modoOscuro, isFalse);
  });

  test('oscuro invierte ink/fondo manteniendo los tonos de marca', () {
    AppColors.configurar(oscuro: true, altoContraste: false);

    // El "ink" (navy) pasa a ser claro sobre fondo oscuro.
    expect(AppColors.navy, isNot(const Color(0xFF2F4156)));
    expect(AppColors.beige, isNot(const Color(0xFFF5EFEB)));
    expect(AppColors.modoOscuro, isTrue);
    // Página, tarjeta y fondo decorativo deben ser TRES grises
    // distintos entre sí (CA real reportado: todo se veía igual de
    // negro) — tarjeta más clara que la página para que se note la
    // elevación.
    expect(AppColors.fondoPagina, isNot(AppColors.white));
    expect(AppColors.fondoPagina, isNot(AppColors.beige));
    expect(AppColors.white, isNot(AppColors.beige));
  });

  test('alto contraste en claro usa negro puro como ink y blanco puro de fondo', () {
    AppColors.configurar(oscuro: false, altoContraste: true);

    expect(AppColors.navy, const Color(0xFF000000));
    expect(AppColors.beige, const Color(0xFFFFFFFF));
    expect(AppColors.fondoPagina, const Color(0xFFFFFFFF));
    expect(AppColors.white, const Color(0xFFFFFFFF));
  });

  test('alto contraste en oscuro usa blanco puro como ink y negro puro de fondo', () {
    AppColors.configurar(oscuro: true, altoContraste: true);

    expect(AppColors.navy, const Color(0xFFFFFFFF));
    expect(AppColors.beige, const Color(0xFF000000));
    expect(AppColors.fondoPagina, const Color(0xFF000000));
    expect(AppColors.white, const Color(0xFF000000));
  });
}
