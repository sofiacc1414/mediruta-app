import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/refrescar_sesion_usecase.dart';

import 'fake_usuario_repository.dart';

void main() {
  group('RefrescarSesionUseCase', () {
    test('devuelve true cuando el repositorio logra renovar la sesión', () async {
      final repo = FakeUsuarioRepository()..refrescarSesionResultado = true;
      final usecase = RefrescarSesionUseCase(repo);

      expect(await usecase.execute(), isTrue);
      expect(repo.ultimaLlamada?['metodo'], 'refrescarSesion');
    });

    test('devuelve false cuando el refresh token ya no sirve', () async {
      final repo = FakeUsuarioRepository()..refrescarSesionResultado = false;
      final usecase = RefrescarSesionUseCase(repo);

      expect(await usecase.execute(), isFalse);
    });
  });
}
