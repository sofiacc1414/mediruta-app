import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/entities/verificacion_direccion.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/autocompletar_direccion_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_perfil_repository.dart';

void main() {
  group('AutocompletarDireccionUseCase', () {
    test('delega texto, departamento y ciudad en el repositorio', () async {
      final repo = FakePerfilRepository();
      final usecase = AutocompletarDireccionUseCase(repo);

      await usecase.execute(
        texto: 'universidad de medellin',
        departamento: 'Antioquia',
        ciudad: 'Medellín',
      );

      expect(repo.ultimaLlamada, {
        'metodo': 'autocompletarDireccion',
        'texto': 'universidad de medellin',
        'departamento': 'Antioquia',
        'ciudad': 'Medellín',
      });
    });

    test('devuelve los candidatos tal cual los resuelve el repositorio', () async {
      final repo = FakePerfilRepository()
        ..candidatosAutocompletarARetornar = const [
          CandidatoDireccionPerfil(
            lat: 6.24,
            lng: -75.58,
            direccionResuelta: 'Universidad de Medellín, Medellín',
            precisa: false,
          ),
        ];
      final usecase = AutocompletarDireccionUseCase(repo);

      final resultado = await usecase.execute(texto: 'universidad de medellin');

      expect(resultado, hasLength(1));
    });

    test('propaga el error del repositorio', () async {
      final repo = FakePerfilRepository()
        ..errorALanzar = const ApiException(statusCode: 500, message: 'error');
      final usecase = AutocompletarDireccionUseCase(repo);

      expect(
        () => usecase.execute(texto: 'calle 27'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
