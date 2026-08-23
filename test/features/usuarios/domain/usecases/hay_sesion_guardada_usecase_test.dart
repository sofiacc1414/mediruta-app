import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/hay_sesion_guardada_usecase.dart';

import 'fake_usuario_repository.dart';

void main() {
  group('HaySesionGuardadaUseCase', () {
    test('devuelve true si el repositorio reporta tokens guardados', () async {
      final repo = FakeUsuarioRepository()..haySesionGuardadaResultado = true;
      final usecase = HaySesionGuardadaUseCase(repo);

      expect(await usecase.execute(), isTrue);
    });

    test('devuelve false si no hay tokens guardados', () async {
      final repo = FakeUsuarioRepository()..haySesionGuardadaResultado = false;
      final usecase = HaySesionGuardadaUseCase(repo);

      expect(await usecase.execute(), isFalse);
    });
  });
}
