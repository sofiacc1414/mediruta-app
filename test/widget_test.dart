// Smoke test de infraestructura: confirma que la app arranca con
// ProviderScope (Riverpod) y el tema oficial sin errores.
// Se reemplaza por pruebas reales de casos de uso cuando se implemente HU-01.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mediruta_app/main.dart';

void main() {
  testWidgets('La app arranca y muestra la pantalla de infraestructura', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MediRutaApp()));

    expect(find.text('MediRuta'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
