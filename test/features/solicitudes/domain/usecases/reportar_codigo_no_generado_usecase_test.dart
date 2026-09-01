import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/reportar_codigo_no_generado_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('ReportarCodigoNoGeneradoUseCase', () {
    test('HU-07 (ronda 3) — delega solicitudId y detalle en el repositorio', () async {
      final repo = FakeSolicitudRepository();
      final useCase = ReportarCodigoNoGeneradoUseCase(repo);

      await useCase.execute('solicitud-uuid');

      expect(repo.ultimaLlamada, {
        'metodo': 'reportarCodigoNoGenerado',
        'solicitudId': 'solicitud-uuid',
        'detalle': null,
      });
    });

    test('propaga el error si el pedido no es del paciente o ya terminó', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(statusCode: 404, message: 'No encontrada.');
      final useCase = ReportarCodigoNoGeneradoUseCase(repo);

      expect(
        () => useCase.execute('solicitud-uuid'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
