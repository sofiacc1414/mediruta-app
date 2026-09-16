import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/precio_pedido.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/enviar_solicitud_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('EnviarSolicitudUseCase', () {
    test('G05 — delega el id en el repositorio y devuelve el código de pedido', () async {
      final repo = FakeSolicitudRepository()..codigoPedidoARetornar = 'MR-000123';
      final useCase = EnviarSolicitudUseCase(repo);

      final resultado = await useCase.execute('solicitud-uuid');

      expect(resultado, 'MR-000123');
      expect(repo.ultimaLlamada, {
        'metodo': 'enviar',
        'solicitudId': 'solicitud-uuid',
        'farmaciaVerificada': null,
        'entregaVerificada': null,
      });
    });

    test('delega la verificación previa de cada dirección cuando el estimado ya las confirmó', () async {
      final repo = FakeSolicitudRepository()..codigoPedidoARetornar = 'MR-000123';
      final useCase = EnviarSolicitudUseCase(repo);
      const farmaciaVerificada = VerificacionDireccionPrevia(
        direccionVerificadaPara: 'Calle 80',
        lat: 6.2,
        lng: -75.6,
      );

      await useCase.execute('solicitud-uuid', farmaciaVerificada: farmaciaVerificada);

      expect(repo.ultimaLlamada, {
        'metodo': 'enviar',
        'solicitudId': 'solicitud-uuid',
        'farmaciaVerificada': farmaciaVerificada,
        'entregaVerificada': null,
      });
    });

    test('propaga el error si falta algún campo obligatorio (422)', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(
          statusCode: 422,
          message: 'La solicitud está incompleta.',
        );
      final useCase = EnviarSolicitudUseCase(repo);

      expect(() => useCase.execute('solicitud-uuid'), throwsA(isA<ApiException>()));
    });
  });
}
