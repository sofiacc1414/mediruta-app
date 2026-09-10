import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/actualizar_nivel_copago_paciente_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_perfil_repository.dart';

void main() {
  group('ActualizarNivelCopagoPacienteUseCase', () {
    test('delega en el repositorio con el id exacto', () async {
      final repo = FakePerfilRepository();
      final useCase = ActualizarNivelCopagoPacienteUseCase(repo);

      await useCase.execute('nivel-uuid');

      expect(repo.ultimaLlamada, {
        'metodo': 'actualizarNivelCopagoPaciente',
        'nivelCopagoId': 'nivel-uuid',
      });
    });

    test('propaga el error del repositorio', () async {
      final repo = FakePerfilRepository()
        ..errorALanzar = const ApiException(statusCode: 404, message: 'No existe.');
      final useCase = ActualizarNivelCopagoPacienteUseCase(repo);

      expect(
        () => useCase.execute('nivel-uuid'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
