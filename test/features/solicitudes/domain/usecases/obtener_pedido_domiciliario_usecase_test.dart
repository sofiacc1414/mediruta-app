import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/pedido_activo.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/obtener_pedido_domiciliario_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('ObtenerPedidoDomiciliarioUseCase', () {
    test('devuelve el detalle (en cualquier estado) que resuelve el repositorio', () async {
      const pedido = PedidoActivo(
        id: 'solicitud-uuid',
        codigoPedido: 'MR-000123',
        estado: 'entregado',
        direccionEntrega: 'Calle 1 #2-3',
        direccionFarmacia: 'Carrera 5 #6-7',
        creadoEn: '2026-08-20T10:00:00.000Z',
        historial: [],
        novedadPropiaAbierta: null,
      );
      final repo = FakeSolicitudRepository()..pedidoActivoARetornar = pedido;
      final useCase = ObtenerPedidoDomiciliarioUseCase(repo);

      final resultado = await useCase.execute('solicitud-uuid');

      expect(resultado, pedido);
      expect(repo.ultimaLlamada, {
        'metodo': 'obtenerPedidoPorId',
        'solicitudId': 'solicitud-uuid',
      });
    });

    test('propaga el error si el id no existe o no es del Domiciliario (404)', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(statusCode: 404, message: 'No encontrado.');
      final useCase = ObtenerPedidoDomiciliarioUseCase(repo);

      expect(() => useCase.execute('solicitud-uuid'), throwsA(isA<ApiException>()));
    });
  });
}
