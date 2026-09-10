import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/entities/nivel_copago.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/listar_niveles_copago_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_perfil_repository.dart';

void main() {
  group('ListarNivelesCopagoUseCase', () {
    test('delega en el repositorio y devuelve el catálogo tal cual', () async {
      const niveles = [
        NivelCopago(id: 'nivel-1', nombre: 'Nivel 1', copago: 8000, orden: 1),
        NivelCopago(id: 'nivel-2', nombre: 'Nivel 2', copago: 15000, orden: 2),
      ];
      final repo = FakePerfilRepository()..nivelesCopagoARetornar = niveles;
      final useCase = ListarNivelesCopagoUseCase(repo);

      final resultado = await useCase.execute();

      expect(resultado, niveles);
      expect(repo.ultimaLlamada, {'metodo': 'listarNivelesCopago'});
    });

    test('propaga el error del repositorio', () async {
      final repo = FakePerfilRepository()
        ..errorALanzar = const ApiException(statusCode: 500, message: 'Error.');
      final useCase = ListarNivelesCopagoUseCase(repo);

      expect(() => useCase.execute(), throwsA(isA<ApiException>()));
    });
  });
}
