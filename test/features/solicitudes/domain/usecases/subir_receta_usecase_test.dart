import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/subir_receta_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('SubirRecetaUseCase', () {
    test('delega solicitudId, bytes, nombre y content type', () async {
      final repo = FakeSolicitudRepository();
      final useCase = SubirRecetaUseCase(repo);
      final bytes = [1, 2, 3];

      await useCase.execute(
        solicitudId: 'solicitud-uuid',
        bytes: bytes,
        nombreArchivo: 'receta.jpg',
        contentType: 'image/jpeg',
      );

      expect(repo.ultimaLlamada, {
        'metodo': 'subirReceta',
        'solicitudId': 'solicitud-uuid',
        'bytes': bytes,
        'nombreArchivo': 'receta.jpg',
        'contentType': 'image/jpeg',
      });
    });

    test('propaga el error si la solicitud ya no está en Borrador', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(statusCode: 404, message: 'No encontrada.');
      final useCase = SubirRecetaUseCase(repo);

      expect(
        () => useCase.execute(
          solicitudId: 'solicitud-uuid',
          bytes: [1],
          nombreArchivo: 'receta.jpg',
          contentType: 'image/jpeg',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
