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
}
