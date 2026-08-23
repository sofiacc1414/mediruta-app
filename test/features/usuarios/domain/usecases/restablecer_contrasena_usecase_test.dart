import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/restablecer_contrasena_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_usuario_repository.dart';

void main() {
  group('RestablecerContrasenaUseCase', () {
    test('G05 (paso 2) — delega correo, código y nueva contraseña', () async {
      final repo = FakeUsuarioRepository();
      final usecase = RestablecerContrasenaUseCase(repo);

      await usecase.execute(
        correo: 'paciente@mail.com',
        codigo: '123456',
        nuevaPassword: 'ClaveNueva1!',
      );

      expect(repo.ultimaLlamada, {
        'metodo': 'restablecerContrasena',
        'correo': 'paciente@mail.com',
        'codigo': '123456',
        'nuevaPassword': 'ClaveNueva1!',
      });
    });

    test('propaga el error genérico ante código inválido/vencido', () async {
      final repo = FakeUsuarioRepository()
        ..errorALanzar = const ApiException(statusCode: 400, message: 'Código inválido.');
      final usecase = RestablecerContrasenaUseCase(repo);

      expect(
        () => usecase.execute(
          correo: 'paciente@mail.com',
          codigo: '000000',
          nuevaPassword: 'ClaveNueva1!',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
