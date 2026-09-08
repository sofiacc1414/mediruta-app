import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/entities/rol_asignado.dart';
import 'package:mediruta_app/features/usuarios/domain/entities/usuario.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/reactivar_cuenta_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_usuario_repository.dart';

void main() {
  group('ReactivarCuentaUseCase', () {
    test('delega en el repositorio y devuelve el usuario ya activo', () async {
      final usuario = const Usuario(
        id: 'usuario-1',
        correo: 'paciente@mail.com',
        estadoCuenta: 'activa',
        roles: [RolAsignado(codigo: 'PACIENTE', estado: 'habilitado')],
      );
      final repo = FakeUsuarioRepository()..usuarioARetornar = usuario;
      final usecase = ReactivarCuentaUseCase(repo);

      final resultado = await usecase.execute(
        correo: 'paciente@mail.com',
        password: 'ClaveValida1!',
      );

      expect(resultado, same(usuario));
      expect(repo.ultimaLlamada, {
        'metodo': 'reactivarCuenta',
        'correo': 'paciente@mail.com',
        'password': 'ClaveValida1!',
      });
    });

    test('propaga el error si la contraseña no coincide o ya no estaba desactivada', () async {
      final repo = FakeUsuarioRepository()
        ..errorALanzar = const ApiException(
          statusCode: 401,
          message: 'Correo o contraseña incorrectos, o la cuenta no está disponible.',
        );
      final usecase = ReactivarCuentaUseCase(repo);

      expect(
        () => usecase.execute(correo: 'x@mail.com', password: 'mala'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
