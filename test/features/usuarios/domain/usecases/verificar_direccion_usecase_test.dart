import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/entities/verificacion_direccion.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/verificar_direccion_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_perfil_repository.dart';

void main() {
  group('VerificarDireccionUseCase', () {
    test('delega dirección, departamento y ciudad en el repositorio', () async {
      final repo = FakePerfilRepository();
      final usecase = VerificarDireccionUseCase(repo);

      await usecase.execute(
        direccion: 'Calle 27 #58-75',
        departamento: 'Antioquia',
        ciudad: 'Medellín',
      );

      expect(repo.ultimaLlamada, {
        'metodo': 'verificarDireccion',
        'direccion': 'Calle 27 #58-75',
        'departamento': 'Antioquia',
        'ciudad': 'Medellín',
      });
    });

    test('devuelve la verificación tal cual la resuelve el repositorio', () async {
      final repo = FakePerfilRepository()
        ..verificacionDireccionARetornar = const VerificacionDireccion(
          direccionResuelta: 'Calle 27, Comuna 15 - Guayabal, Medellín',
          precisa: false,
          candidatos: [
            CandidatoDireccionPerfil(
              lat: 6.15,
              lng: -75.6,
              direccionResuelta: 'Calle 27, Comuna 16 - Belén, Medellín',
              precisa: true,
            ),
          ],
        );
      final usecase = VerificarDireccionUseCase(repo);

      final resultado = await usecase.execute(direccion: 'Calle 27');

      expect(resultado.direccionResuelta, 'Calle 27, Comuna 15 - Guayabal, Medellín');
      expect(resultado.precisa, false);
      expect(resultado.candidatos, hasLength(1));
    });

    test('propaga el error del repositorio', () async {
      final repo = FakePerfilRepository()
        ..errorALanzar = const ApiException(statusCode: 500, message: 'error');
      final usecase = VerificarDireccionUseCase(repo);

      expect(
        () => usecase.execute(direccion: 'Calle 27'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
