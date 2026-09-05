import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/adjuntar_receta_propuesta_edicion_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('AdjuntarRecetaPropuestaEdicionUseCase', () {
    test('delega solicitudId, novedadId, bytes, nombre y content type', () async {
      final repo = FakeSolicitudRepository();
      final useCase = AdjuntarRecetaPropuestaEdicionUseCase(repo);
      final bytes = [1, 2, 3];

      await useCase.execute(
        solicitudId: 'solicitud-uuid',
        novedadId: 'novedad-uuid',
        bytes: bytes,
        nombreArchivo: 'receta_propuesta.jpg',
        contentType: 'image/jpeg',
      );

      expect(repo.ultimaLlamada, {
        'metodo': 'adjuntarRecetaPropuestaEdicion',
        'solicitudId': 'solicitud-uuid',
        'novedadId': 'novedad-uuid',
        'bytes': bytes,
        'nombreArchivo': 'receta_propuesta.jpg',
        'contentType': 'image/jpeg',
      });
    });

    test('propaga el error si la novedad no existe, no es del paciente o ya se resolvió', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(statusCode: 404, message: 'No encontrada.');
      final useCase = AdjuntarRecetaPropuestaEdicionUseCase(repo);

      expect(
        () => useCase.execute(
          solicitudId: 'solicitud-uuid',
          novedadId: 'novedad-uuid',
          bytes: [1],
          nombreArchivo: 'receta_propuesta.jpg',
          contentType: 'image/jpeg',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
