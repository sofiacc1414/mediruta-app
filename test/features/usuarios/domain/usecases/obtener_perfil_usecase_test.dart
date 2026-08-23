import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/obtener_perfil_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_perfil_repository.dart';

void main() {
  group('ObtenerPerfilUseCase', () {
    test('G02 — devuelve el perfil que resuelve el repositorio', () async {
      final repo = FakePerfilRepository();
      final usecase = ObtenerPerfilUseCase(repo);

      final resultado = await usecase.execute();

      expect(resultado, same(repo.perfilARetornar));
      expect(repo.ultimaLlamada?['metodo'], 'obtenerPerfil');
    });

    test('propaga el error si la sesión ya no es válida', () async {
      final repo = FakePerfilRepository()
        ..errorALanzar = const ApiException(statusCode: 401, message: 'No autorizado.');
      final usecase = ObtenerPerfilUseCase(repo);

      expect(() => usecase.execute(), throwsA(isA<ApiException>()));
    });
  });
}
