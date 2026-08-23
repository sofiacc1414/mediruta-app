import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/cambiar_contrasena_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_usuario_repository.dart';

void main() {
  group('CambiarContrasenaUseCase', () {
    test('G06 — delega la contraseña actual y la nueva', () async {
      final repo = FakeUsuarioRepository();
      final usecase = CambiarContrasenaUseCase(repo);

      await usecase.execute(
        passwordActual: 'ClaveActual1!',
        nuevaPassword: 'ClaveNueva1!',
      );

      expect(repo.ultimaLlamada, {
        'metodo': 'cambiarContrasena',
        'passwordActual': 'ClaveActual1!',
        'nuevaPassword': 'ClaveNueva1!',
      });
    });

    test('propaga el error si la contraseña actual no coincide', () async {
      final repo = FakeUsuarioRepository()
        ..errorALanzar = const ApiException(
          statusCode: 400,
          message: 'La contraseña actual no es correcta.',
        );
      final usecase = CambiarContrasenaUseCase(repo);

      expect(
        () => usecase.execute(
          passwordActual: 'Incorrecta1!',
          nuevaPassword: 'ClaveNueva1!',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
