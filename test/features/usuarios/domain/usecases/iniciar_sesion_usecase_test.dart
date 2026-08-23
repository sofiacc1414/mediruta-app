import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/entities/rol_asignado.dart';
import 'package:mediruta_app/features/usuarios/domain/entities/usuario.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/iniciar_sesion_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_usuario_repository.dart';

void main() {
  group('IniciarSesionUseCase', () {
    test('G03 — devuelve el usuario que resuelve el repositorio', () async {
      final usuario = const Usuario(
        id: 'usuario-1',
        correo: 'paciente@mail.com',
        estadoCuenta: 'activa',
        roles: [RolAsignado(codigo: 'PACIENTE', estado: 'habilitado')],
      );
      final repo = FakeUsuarioRepository()..usuarioARetornar = usuario;
      final usecase = IniciarSesionUseCase(repo);

      final resultado = await usecase.execute(
        correo: 'paciente@mail.com',
        password: 'ClaveValida1!',
      );

      expect(resultado, same(usuario));
      expect(repo.ultimaLlamada, {
        'metodo': 'iniciarSesion',
        'correo': 'paciente@mail.com',
        'password': 'ClaveValida1!',
      });
    });

    test('G04 — propaga el error genérico de credenciales inválidas', () async {
      final repo = FakeUsuarioRepository()
        ..errorALanzar = const ApiException(
          statusCode: 401,
          message: 'Correo o contraseña incorrectos, o la cuenta no está disponible.',
        );
      final usecase = IniciarSesionUseCase(repo);

      expect(
        () => usecase.execute(correo: 'x@mail.com', password: 'mala'),
        throwsA(isA<ApiException>().having((e) => e.esNoAutorizado, 'esNoAutorizado', true)),
      );
    });
  });
}
