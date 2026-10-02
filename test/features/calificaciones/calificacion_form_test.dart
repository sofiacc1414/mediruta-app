import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/calificaciones/presentation/screens/calificacion_confirmacion_screen.dart';
import 'package:mediruta_app/features/calificaciones/presentation/screens/calificacion_form_screen.dart';
import 'package:mediruta_app/features/calificaciones/presentation/widgets/aviso_calificacion.dart';

void main() {
  testWidgets('pedido no entregado muestra el bloqueo', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
        home: CalificacionFormScreen(
          args: CalificacionFormArgs(
            pedidoId: '11111111-1111-1111-1111-111111111111',
            codigoPedido: 'MR-000001',
            estadoPedido: 'en_camino_entrega',
            editar: false,
          ),
        ),
      ),
      ),
    );

    expect(find.text('Aún no puedes calificar este pedido'), findsOneWidget);
    expect(
      find.text('Solo puedes calificar cuando el pedido haya sido entregado.'),
      findsOneWidget,
    );
    expect(find.byType(AvisoCalificacion), findsOneWidget);
  });

  testWidgets('crear calificación muestra el formulario vacío', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
        home: CalificacionFormScreen(
          args: CalificacionFormArgs(
            pedidoId: '11111111-1111-1111-1111-111111111111',
            codigoPedido: 'MR-000124',
            estadoPedido: 'entregado',
            editar: false,
          ),
        ),
      ),
      ),
    );

    expect(find.text('Tu experiencia con MediRuta'), findsOneWidget);
    expect(find.text('Comparte tu momento'), findsOneWidget);
    expect(find.text('¿Qué fue lo que más valoraste de tu experiencia?'), findsOneWidget);
    expect(find.text('Compartir mi experiencia'), findsOneWidget);
    expect(find.text('Muy buena'), findsNothing);
  });

  testWidgets('en un iPhone pequeño no hay overflow', (tester) async {
    await _montarCrear(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
    expect(find.text('Tu experiencia con MediRuta'), findsOneWidget);
    expect(find.text('Compartir mi experiencia'), findsOneWidget);
    final imagen = tester.getRect(find.byType(Image));
    final titulo = tester.getRect(find.text('Tu experiencia con MediRuta'));
    expect(titulo.top, greaterThanOrEqualTo(imagen.bottom - 1));
    final boton = tester.getRect(find.text('Compartir mi experiencia'));
    expect(boton.bottom, lessThanOrEqualTo(568));
  });

  testWidgets('en iPhone SE y iPhone estándar cabe sin scroll', (tester) async {
    for (final tamano in [const Size(375, 667), const Size(390, 844)]) {
      await _montarCrear(tester, tamano);
      expect(tester.takeException(), isNull);
      final boton = tester.getRect(find.text('Compartir mi experiencia'));
      expect(boton.bottom, lessThanOrEqualTo(tamano.height));
      expect(find.byType(ListView), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('la frase cambia al elegir estrellas', (tester) async {
    await _montarCrear(tester, const Size(390, 844));
    await tester.tap(find.byKey(const Key('estrella-5')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Gracias por confiar en MediRuta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la pantalla de gracias cabe en un iPhone pequeño', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CalificacionConfirmacionScreen(pedidoId: '11111111-1111-1111-1111-111111111111'),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('¡Gracias por compartir!'), findsOneWidget);
    expect(find.text('Volver a mis pedidos'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });
}

Future<void> _montarCrear(WidgetTester tester, Size tamano) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        home: CalificacionFormScreen(
          args: CalificacionFormArgs(
            pedidoId: '11111111-1111-1111-1111-111111111111',
            codigoPedido: 'MR-000124',
            estadoPedido: 'entregado',
            editar: false,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
