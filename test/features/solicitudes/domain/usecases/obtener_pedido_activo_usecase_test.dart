import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/pedido_activo.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/obtener_pedido_activo_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('ObtenerPedidoActivoUseCase', () {
    test('devuelve null si el Domiciliario no tiene ningún pedido activo', () async {
      final repo = FakeSolicitudRepository()..pedidoActivoARetornar = null;
      final useCase = ObtenerPedidoActivoUseCase(repo);

      final resultado = await useCase.execute();

      expect(resultado, isNull);
      expect(repo.ultimaLlamada, {'metodo': 'obtenerPedidoActivo'});
    });

    test('devuelve el pedido que resuelve el repositorio', () async {
      const pedido = PedidoActivo(
        id: 'solicitud-uuid',
        codigoPedido: 'MR-000123',
        estado: 'en_camino_entrega',
        direccionEntrega: 'Calle 1 #2-3',
        direccionFarmacia: 'Carrera 5 #6-7',
        creadoEn: '2026-08-20T10:00:00.000Z',
        historial: [],
        novedadPropiaAbierta: null,
      );
      final repo = FakeSolicitudRepository()..pedidoActivoARetornar = pedido;
      final useCase = ObtenerPedidoActivoUseCase(repo);

      final resultado = await useCase.execute();

      expect(resultado, pedido);
    });

    test('propaga el error si la sesión ya no es válida', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(statusCode: 401, message: 'No autorizado.');
      final useCase = ObtenerPedidoActivoUseCase(repo);

      expect(() => useCase.execute(), throwsA(isA<ApiException>()));
    });
  });
}
