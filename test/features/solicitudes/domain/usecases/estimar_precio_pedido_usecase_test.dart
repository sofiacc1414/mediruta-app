import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/precio_pedido.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/estimar_precio_pedido_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('EstimarPrecioPedidoUseCase', () {
    test('delega ambas direcciones en el repositorio y devuelve el precio', () async {
      final precio = PrecioPedido.disponible(
        copago: 15000,
        domicilio: 26644,
        total: 41644,
        distanciaKm: 2.6,
      );
      final repo = FakeSolicitudRepository()..precioEstimadoARetornar = precio;
      final useCase = EstimarPrecioPedidoUseCase(repo);

      final resultado = await useCase.execute(
        direccionFarmacia: 'Carrera 70 #44-50',
        direccionEntrega: 'Carrera 43A #5A-113',
      );

      expect(resultado, precio);
      expect(repo.ultimaLlamada, {
        'metodo': 'estimarPrecio',
        'direccionFarmacia': 'Carrera 70 #44-50',
        'direccionEntrega': 'Carrera 43A #5A-113',
      });
    });

    test('propaga el error del repositorio', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiSinConexionException();
      final useCase = EstimarPrecioPedidoUseCase(repo);

      expect(
        () => useCase.execute(direccionFarmacia: 'X', direccionEntrega: 'Y'),
        throwsA(isA<ApiSinConexionException>()),
      );
    });
  });
}
