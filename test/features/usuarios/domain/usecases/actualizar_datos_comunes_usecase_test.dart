import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/actualizar_datos_comunes_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_perfil_repository.dart';

void main() {
  group('ActualizarDatosComunesUseCase', () {
    test('G03 — delega nombre y teléfono al repositorio', () async {
      final repo = FakePerfilRepository();
      final usecase = ActualizarDatosComunesUseCase(repo);

      await usecase.execute(
        nombreCompleto: 'Persona de Prueba',
        telefono: '3001234567',
      );

      expect(repo.ultimaLlamada, {
        'metodo': 'actualizarDatosComunes',
        'nombreCompleto': 'Persona de Prueba',
        'telefono': '3001234567',
      });
    });

    test('propaga el error de validación (G04)', () async {
      final repo = FakePerfilRepository()
        ..errorALanzar = const ApiException(statusCode: 400, message: 'Teléfono inválido.');
      final usecase = ActualizarDatosComunesUseCase(repo);

      expect(
        () => usecase.execute(nombreCompleto: 'Persona', telefono: 'abc'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
