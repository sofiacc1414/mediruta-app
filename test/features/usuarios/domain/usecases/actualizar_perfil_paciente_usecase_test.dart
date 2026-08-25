import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/actualizar_perfil_paciente_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_perfil_repository.dart';

void main() {
  group('ActualizarPerfilPacienteUseCase', () {
    test('G01/G03 — delega dirección y fecha de nacimiento', () async {
      final repo = FakePerfilRepository();
      final usecase = ActualizarPerfilPacienteUseCase(repo);

      await usecase.execute(
        direccion: 'Calle 123 #45-67',
        fechaNacimiento: '1990-05-10',
        departamento: 'Cundinamarca',
        ciudad: 'Bogotá',
      );

      expect(repo.ultimaLlamada, {
        'metodo': 'actualizarPerfilPaciente',
        'direccion': 'Calle 123 #45-67',
        'fechaNacimiento': '1990-05-10',
        'departamento': 'Cundinamarca',
        'ciudad': 'Bogotá',
      });
    });

    test('propaga el error si la cuenta no tiene rol PACIENTE', () async {
      final repo = FakePerfilRepository()
        ..errorALanzar = const ApiException(statusCode: 403, message: 'Rol no autorizado.');
      final usecase = ActualizarPerfilPacienteUseCase(repo);

      expect(
        () => usecase.execute(
          direccion: 'Calle 123',
          fechaNacimiento: '1990-05-10',
          departamento: 'Cundinamarca',
          ciudad: 'Bogotá',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
