import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/cancelar_solicitud_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('CancelarSolicitudUseCase', () {
    test('G06 — delega el id en el repositorio', () async {
      final repo = FakeSolicitudRepository();
      final useCase = CancelarSolicitudUseCase(repo);

      await useCase.execute('solicitud-uuid');

      expect(repo.ultimaLlamada, {'metodo': 'cancelar', 'solicitudId': 'solicitud-uuid'});
    });

    test('propaga el error si ya estaba cancelada o no existe', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(statusCode: 404, message: 'No encontrada.');
      final useCase = CancelarSolicitudUseCase(repo);

      expect(() => useCase.execute('solicitud-uuid'), throwsA(isA<ApiException>()));
    });
  });
}
