import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/subir_foto_cedula_paciente_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_perfil_repository.dart';

void main() {
  group('SubirFotoCedulaPacienteUseCase', () {
    test('G01/G03 — delega bytes, nombre y content type', () async {
      final repo = FakePerfilRepository();
      final usecase = SubirFotoCedulaPacienteUseCase(repo);
      final bytes = [1, 2, 3];

      await usecase.execute(
        bytes: bytes,
        nombreArchivo: 'cedula.jpg',
        contentType: 'image/jpeg',
      );

      expect(repo.ultimaLlamada, {
        'metodo': 'subirFotoCedulaPaciente',
        'bytes': bytes,
        'nombreArchivo': 'cedula.jpg',
        'contentType': 'image/jpeg',
      });
    });

    test('propaga el error si la cuenta no tiene rol PACIENTE', () async {
      final repo = FakePerfilRepository()
        ..errorALanzar = const ApiException(statusCode: 403, message: 'Rol no autorizado.');
      final usecase = SubirFotoCedulaPacienteUseCase(repo);

      expect(
        () => usecase.execute(
          bytes: [1],
          nombreArchivo: 'cedula.jpg',
          contentType: 'image/jpeg',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
