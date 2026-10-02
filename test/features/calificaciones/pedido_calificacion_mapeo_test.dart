import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/calificaciones/data/datasources/calificacion_remote_datasource.dart';
import 'package:mediruta_app/features/calificaciones/domain/entities/calificacion.dart';

void main() {
  test('el resumen de GET /solicitudes se adapta a PedidoCalificacion', () {
    final json = pedidoCalificacionDesdeSolicitud(
      {
        'id': 'pedido-1',
        'codigoPedido': 'MR-000124',
        'estado': 'entregado',
        'creadoEn': '2026-03-12T00:00:00.000Z',
      },
      cantidadMedicamentos: 3,
      tieneCalificacionActiva: false,
    );

    final pedido = PedidoCalificacion.fromJson(json);

    expect(pedido.id, 'pedido-1');
    expect(pedido.codigoPedido, 'MR-000124');
    expect(pedido.estado, 'entregado');
    expect(pedido.cantidadMedicamentos, 3);
    expect(pedido.tieneCalificacionActiva, isFalse);
  });

  test('un pedido en proceso conserva su estado para las pestañas', () {
    final pedido = PedidoCalificacion.fromJson(
      pedidoCalificacionDesdeSolicitud(
        {
          'id': 'pedido-2',
          'codigoPedido': 'MR-000010',
          'estado': 'en_camino_entrega',
          'creadoEn': '2026-03-01T00:00:00.000Z',
        },
        cantidadMedicamentos: 1,
        tieneCalificacionActiva: false,
      ),
    );

    expect(pedido.estado, 'en_camino_entrega');
    expect(pedido.tieneCalificacionActiva, isFalse);
  });
}
