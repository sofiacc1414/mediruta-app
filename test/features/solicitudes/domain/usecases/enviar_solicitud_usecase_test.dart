import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/enviar_solicitud_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('EnviarSolicitudUseCase', () {
    test('G05 — delega el id en el repositorio', () async {
      final repo = FakeSolicitudRepository();
      final useCase = EnviarSolicitudUseCase(repo);

      await useCase.execute('solicitud-uuid');

      expect(repo.ultimaLlamada, {'metodo': 'enviar', 'solicitudId': 'solicitud-uuid'});
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
