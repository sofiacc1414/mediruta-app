import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/datos_solicitud.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/medicamento.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/actualizar_solicitud_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('ActualizarSolicitudUseCase', () {
    test('G04 — delega el id y los datos en el repositorio', () async {
      final repo = FakeSolicitudRepository();
      final useCase = ActualizarSolicitudUseCase(repo);
      const datos = DatosSolicitud(
        medicamentos: [Medicamento(nombre: 'Acetaminofén')],
      );

      await useCase.execute('solicitud-uuid', datos);

      expect(repo.ultimaLlamada, {
        'metodo': 'actualizar',
        'solicitudId': 'solicitud-uuid',
        'datos': datos,
      });
    });

    test('propaga el error si ya no está en Borrador', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(statusCode: 404, message: 'No encontrada.');
      final useCase = ActualizarSolicitudUseCase(repo);

      expect(
        () => useCase.execute('solicitud-uuid', const DatosSolicitud()),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
