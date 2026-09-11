import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/shared/widgets/app_status_pill.dart';

Future<void> _pump(WidgetTester tester, String estado) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: AppStatusPill(estado: estado))),
  );
}

void main() {
  testWidgets('en_asignacion muestra "Buscando domiciliario" con ícono de búsqueda', (
    tester,
  ) async {
    await _pump(tester, 'en_asignacion');
    expect(find.text('Buscando domiciliario'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('entregado muestra "Entregado" con ícono de check', (tester) async {
    await _pump(tester, 'entregado');
    expect(find.text('Entregado'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('cancelada muestra "Cancelada" con ícono de cerrar', (tester) async {
    await _pump(tester, 'cancelada');
    expect(find.text('Cancelada'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('un estado desconocido cae al texto tal cual, sin ícono', (tester) async {
    await _pump(tester, 'algo_nuevo');
    expect(find.text('algo_nuevo'), findsOneWidget);
  });

  testWidgets('pendiente_revision se muestra como "Pedido generado"', (tester) async {
    await _pump(tester, 'pendiente_revision');
    expect(find.text('Pedido generado'), findsOneWidget);
  });

  testWidgets(
    'con texto a 1.3x (modo adulto mayor) y poco ancho, no desborda su Row — el label trunca',
    (tester) async {
      // Reproduce el layout real que rompía: un ícono/avatar fijo +
      // un Expanded con otro texto + el pill sin envolver, en un
      // ancho angosto — antes de envolverlo en `Flexible` (y del
      // `Text` interno en otro `Flexible` con ellipsis), esto tiraba
      // un RenderFlex overflow ("Buscando domiciliario" a 1.3x no
      // entraba).
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
              body: SizedBox(
                width: 220,
                child: Row(
                  children: [
                    const SizedBox(width: 52, height: 52),
                    const SizedBox(width: 14),
                    const Expanded(child: Text('Farmacia Central')),
                    const SizedBox(width: 8),
                    Flexible(child: AppStatusPill(estado: 'en_asignacion')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );
}
