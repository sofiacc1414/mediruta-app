import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/solicitar_rol_paciente_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_usuario_repository.dart';

void main() {
  group('SolicitarRolPacienteUseCase', () {
    test('delega en el repositorio y devuelve el mensaje', () async {
      final repo = FakeUsuarioRepository()
        ..solicitarRolPacienteResultado = 'Ahora también sos Paciente.';
      final usecase = SolicitarRolPacienteUseCase(repo);

      final resultado = await usecase.execute();

      expect(resultado, 'Ahora también sos Paciente.');
      expect(repo.ultimaLlamada, {'metodo': 'solicitarRolPaciente'});
    });

    test('propaga el error del repositorio', () async {
      final repo = FakeUsuarioRepository()
        ..errorALanzar = const ApiException(statusCode: 401, message: 'No autorizado.');
      final usecase = SolicitarRolPacienteUseCase(repo);

      expect(() => usecase.execute(), throwsA(isA<ApiException>()));
    });
  });
}
