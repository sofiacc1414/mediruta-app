import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/solicitar_recuperacion_contrasena_usecase.dart';

import 'fake_usuario_repository.dart';

void main() {
  group('SolicitarRecuperacionContrasenaUseCase', () {
    test('G05 (paso 1) — delega la solicitud con el correo exacto', () async {
      final repo = FakeUsuarioRepository();
      final usecase = SolicitarRecuperacionContrasenaUseCase(repo);

      await usecase.execute(correo: 'paciente@mail.com');

      expect(repo.ultimaLlamada, {
        'metodo': 'solicitarRecuperacionContrasena',
        'correo': 'paciente@mail.com',
      });
    });
  });
}
