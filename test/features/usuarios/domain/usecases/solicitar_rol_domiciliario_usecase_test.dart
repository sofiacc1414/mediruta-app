import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/solicitar_rol_domiciliario_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_usuario_repository.dart';

void main() {
  group('SolicitarRolDomiciliarioUseCase', () {
    test('delega en el repositorio y devuelve el mensaje', () async {
      final repo = FakeUsuarioRepository()
        ..solicitarRolDomiciliarioResultado = 'Listo, completá tus datos.';
      final usecase = SolicitarRolDomiciliarioUseCase(repo);

      final resultado = await usecase.execute();

      expect(resultado, 'Listo, completá tus datos.');
      expect(repo.ultimaLlamada, {'metodo': 'solicitarRolDomiciliario'});
    });

    test('propaga el error del repositorio', () async {
      final repo = FakeUsuarioRepository()
        ..errorALanzar = const ApiException(statusCode: 401, message: 'No autorizado.');
      final usecase = SolicitarRolDomiciliarioUseCase(repo);

      expect(() => usecase.execute(), throwsA(isA<ApiException>()));
    });
  });
}
