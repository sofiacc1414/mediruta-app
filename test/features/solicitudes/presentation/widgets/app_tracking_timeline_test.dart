import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/evento_historial.dart';
import 'package:mediruta_app/features/solicitudes/presentation/widgets/app_tracking_timeline.dart';
import 'package:mediruta_app/shared/core/theme/app_colors.dart';

void main() {
  testWidgets('muestra los 8 pasos con sus etiquetas', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppTrackingTimeline(estadoActual: 'pendiente_revision', historial: []),
        ),
      ),
    );

    expect(find.text('Pedido generado'), findsOneWidget);
    expect(find.text('Buscando domiciliario'), findsOneWidget);
    expect(find.text('Domiciliario en camino a la farmacia'), findsOneWidget);
    expect(find.text('Domiciliario en la farmacia'), findsOneWidget);
    expect(find.text('Medicamentos recogidos'), findsOneWidget);
    expect(find.text('Yendo a tu dirección'), findsOneWidget);
    expect(find.text('En sitio'), findsOneWidget);
    expect(find.text('Entregado'), findsOneWidget);
  });

  testWidgets(
    'bug real: en_farmacia pintaba todos los pasos como no alcanzados '
    '(faltaba en la lista de pasos, indexOf devolvía -1)',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTrackingTimeline(estadoActual: 'en_farmacia', historial: []),
          ),
        ),
      );

      final circulos = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration && (c.decoration! as BoxDecoration).shape == BoxShape.circle)
          .toList();
      expect(circulos, hasLength(8));

      final pintados = circulos.where((c) {
        final decoracion = c.decoration! as BoxDecoration;
        return decoracion.color == AppColors.navy;
      }).length;
      // Hasta "en_farmacia" inclusive: pendiente_revision, en_asignacion,
      // asignado_en_camino_farmacia, en_farmacia = 4 pasos alcanzados.
      expect(pintados, 4);
    },
  );

  testWidgets('muestra la hora del historial en el paso que la tiene', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppTrackingTimeline(
            estadoActual: 'en_asignacion',
            historial: [
              EventoHistorial(estado: 'pendiente_revision', creadoEn: '2026-08-24T10:15:00.000Z'),
              EventoHistorial(estado: 'en_asignacion', creadoEn: '2026-08-24T10:15:01.000Z'),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('24 ago'), findsNWidgets(2));
    // un paso todavía no alcanzado (medicamentos_recogidos) no tiene hora.
    expect(find.text('Medicamentos recogidos'), findsOneWidget);
  });

  testWidgets('muestra la acción embebida solo en el paso actual', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTrackingTimeline(
            estadoActual: 'en_sitio',
            historial: const [],
            accionPasoActual: const Text('BOTON_ACCION'),
          ),
        ),
      ),
    );

    expect(find.text('BOTON_ACCION'), findsOneWidget);
  });

  testWidgets('sin acción, ningún paso la muestra', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppTrackingTimeline(estadoActual: 'en_sitio', historial: []),
        ),
      ),
    );

    expect(find.text('BOTON_ACCION'), findsNothing);
  });
}
