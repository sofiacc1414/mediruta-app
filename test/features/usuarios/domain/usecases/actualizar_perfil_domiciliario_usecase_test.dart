import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/actualizar_perfil_domiciliario_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_perfil_repository.dart';

void main() {
  group('ActualizarPerfilDomiciliarioUseCase', () {
    test('G01/G03 — delega dirección y vehículo', () async {
      final repo = FakePerfilRepository();
      final usecase = ActualizarPerfilDomiciliarioUseCase(repo);

      await usecase.execute(
        direccion: 'Calle 123 #45-67',
        vehiculoTipo: 'Moto',
        vehiculoPlaca: 'ABC123',
      );

      expect(repo.ultimaLlamada, {
        'metodo': 'actualizarPerfilDomiciliario',
        'direccion': 'Calle 123 #45-67',
        'vehiculoTipo': 'Moto',
        'vehiculoPlaca': 'ABC123',
      });
    });

    test('propaga el error si la cuenta no tiene rol DOMICILIARIO', () async {
      final repo = FakePerfilRepository()
        ..errorALanzar = const ApiException(statusCode: 403, message: 'Rol no autorizado.');
      final usecase = ActualizarPerfilDomiciliarioUseCase(repo);

      expect(
        () => usecase.execute(
          direccion: 'Calle 123',
          vehiculoTipo: 'Moto',
          vehiculoPlaca: 'ABC123',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
