import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/registrar_usuario_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_usuario_repository.dart';

void main() {
  group('RegistrarUsuarioUseCase', () {
    test('delega el registro al repositorio con los datos exactos', () async {
      final repo = FakeUsuarioRepository();
      final usecase = RegistrarUsuarioUseCase(repo);

      await usecase.execute(
        correo: 'paciente@mail.com',
        password: 'ClaveValida1!',
        tipoRegistro: 'PACIENTE',
      );

      expect(repo.ultimaLlamada, {
        'metodo': 'registrar',
        'correo': 'paciente@mail.com',
        'password': 'ClaveValida1!',
        'tipoRegistro': 'PACIENTE',
      });
    });

    test('propaga el error de dominio del repositorio (G02)', () async {
      final repo = FakeUsuarioRepository()
        ..errorALanzar = const ApiException(
          statusCode: 409,
          message: 'El correo ya está registrado.',
        );
      final usecase = RegistrarUsuarioUseCase(repo);

      expect(
        () => usecase.execute(
          correo: 'repetido@mail.com',
          password: 'ClaveValida1!',
          tipoRegistro: 'PACIENTE',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
