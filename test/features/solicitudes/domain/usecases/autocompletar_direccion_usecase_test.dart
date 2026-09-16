import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/precio_pedido.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/autocompletar_direccion_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('AutocompletarDireccionUseCase', () {
    test('delega el texto en el repositorio y devuelve los candidatos', () async {
      const candidatos = [
        CandidatoDireccion(
          lat: 6.24,
          lng: -75.58,
          direccionResuelta: 'Universidad de Medellín, Medellín',
          precisa: false,
        ),
      ];
      final repo = FakeSolicitudRepository()
        ..candidatosAutocompletarARetornar = candidatos;
      final useCase = AutocompletarDireccionUseCase(repo);

      final resultado = await useCase.execute('universidad de medellin');

      expect(resultado, candidatos);
      expect(repo.ultimaLlamada, {
        'metodo': 'autocompletarDireccion',
        'texto': 'universidad de medellin',
      });
    });

    test('propaga el error del repositorio', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiSinConexionException();
      final useCase = AutocompletarDireccionUseCase(repo);

      expect(
        () => useCase.execute('calle 27'),
        throwsA(isA<ApiSinConexionException>()),
      );
    });
  });
}
