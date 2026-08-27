import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/reportar_novedad_paciente_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('ReportarNovedadPacienteUseCase', () {
    test('HU-07 — delega solicitudId y detalle en el repositorio', () async {
      final repo = FakeSolicitudRepository();
      final useCase = ReportarNovedadPacienteUseCase(repo);

      await useCase.execute('solicitud-uuid', 'El domiciliario no contesta');

      expect(repo.ultimaLlamada, {
        'metodo': 'reportarNovedadPaciente',
        'solicitudId': 'solicitud-uuid',
        'detalle': 'El domiciliario no contesta',
      });
    });

    test('propaga el error si el pedido no es del paciente o ya terminó', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(statusCode: 404, message: 'No encontrada.');
      final useCase = ReportarNovedadPacienteUseCase(repo);

      expect(
        () => useCase.execute('solicitud-uuid', 'detalle'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
