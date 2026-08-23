import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/entities/usuario.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/obtener_sesion_actual_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_usuario_repository.dart';

void main() {
  group('ObtenerSesionActualUseCase', () {
    test('devuelve la identidad de GET /auth/me', () async {
      final usuario = const Usuario(
        id: 'usuario-1',
        correo: 'paciente@mail.com',
        estadoCuenta: 'activa',
        roles: [],
      );
      final repo = FakeUsuarioRepository()..usuarioARetornar = usuario;
      final usecase = ObtenerSesionActualUseCase(repo);

      expect(await usecase.execute(), same(usuario));
      expect(repo.ultimaLlamada?['metodo'], 'obtenerSesionActual');
    });

    test('propaga 401 cuando la sesión ya no es válida', () async {
      final repo = FakeUsuarioRepository()
        ..errorALanzar = const ApiException(statusCode: 401, message: 'No autorizado.');
      final usecase = ObtenerSesionActualUseCase(repo);

      expect(() => usecase.execute(), throwsA(isA<ApiException>()));
    });
  });
}
