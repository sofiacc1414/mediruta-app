import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/cerrar_sesion_usecase.dart';

import 'fake_usuario_repository.dart';

void main() {
  group('CerrarSesionUseCase', () {
    test('G07 — delega el cierre de sesión al repositorio', () async {
      final repo = FakeUsuarioRepository();
      final usecase = CerrarSesionUseCase(repo);

      await usecase.execute();

      expect(repo.ultimaLlamada?['metodo'], 'cerrarSesion');
    });
  });
}
