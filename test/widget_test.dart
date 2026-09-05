// Smoke test de infraestructura: confirma que la app arranca con
// ProviderScope (Riverpod), el tema oficial y el AuthGate de HU-01 sin
// errores — onboarding primero, login después de "Comenzar", cuando no
// hay sesión guardada.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mediruta_app/main.dart';

void main() {
  setUp(() {
    // Sin esto, ApiClient/HaySesionGuardadaUseCase intentan leer el canal
    // de plataforma real de flutter_secure_storage, que no existe en el
    // entorno de test (MissingPluginException).
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
  });

  testWidgets(
    'Sin sesión guardada, la app arranca en onboarding y pasa a login al tocar Comenzar',
    (WidgetTester tester) async {
      // No se usa pumpAndSettle acá: el onboarding tiene un pulso
      // (`AnimationController.repeat(reverse: true)`) que nunca termina,
      // así que pumpAndSettle esperaría para siempre. Se pumpea un tiempo
      // fijo, suficiente para que se resuelva el chequeo de sesión
      // guardada y la transición de ruta.
      await tester.pumpWidget(const ProviderScope(child: MediRutaApp()));
      // El botón "Comenzar" vive en la 2da slide del onboarding, a la
      // que se llega solo por auto-slide (`Future.delayed` de 10s) o
      // deslizando — se pumpea más de 10s simulados para llegar ahí.
      for (var i = 0; i < 65; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('Comenzar'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsNothing);

      await tester.tap(find.text('Comenzar'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Iniciar sesión'), findsWidgets);
      expect(find.byType(Scaffold), findsOneWidget);
    },
  );
}
