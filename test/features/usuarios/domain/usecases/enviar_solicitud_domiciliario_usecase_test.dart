import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/enviar_solicitud_domiciliario_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_usuario_repository.dart';

void main() {
  group('EnviarSolicitudDomiciliarioUseCase', () {
    test('delega en el repositorio y devuelve el mensaje', () async {
      final repo = FakeUsuarioRepository()
        ..enviarSolicitudDomiciliarioResultado = 'Tu solicitud fue enviada para validación.';
      final usecase = EnviarSolicitudDomiciliarioUseCase(repo);

      final resultado = await usecase.execute();

      expect(resultado, 'Tu solicitud fue enviada para validación.');
      expect(repo.ultimaLlamada, {'metodo': 'enviarSolicitudDomiciliario'});
    });

    test('propaga el error si falta algún dato obligatorio (422)', () async {
      final repo = FakeUsuarioRepository()
        ..errorALanzar = const ApiException(
          statusCode: 422,
          message: 'La documentación del domiciliario está incompleta.',
        );
      final usecase = EnviarSolicitudDomiciliarioUseCase(repo);

      expect(() => usecase.execute(), throwsA(isA<ApiException>()));
    });
  });
}
