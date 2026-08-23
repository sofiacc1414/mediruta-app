import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/solicitud_resumen.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/listar_solicitudes_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('ListarSolicitudesUseCase', () {
    test('G02 — devuelve la lista que resuelve el repositorio', () async {
      final lista = [
        const SolicitudResumen(
          id: 'solicitud-uuid',
          codigoPedido: null,
          estado: 'borrador',
          creadoEn: '2026-08-20T10:00:00.000Z',
        ),
      ];
      final repo = FakeSolicitudRepository()..listaARetornar = lista;
      final useCase = ListarSolicitudesUseCase(repo);

      final resultado = await useCase.execute();

      expect(resultado, lista);
      expect(repo.ultimaLlamada?['metodo'], 'listar');
    });

    test('propaga el error si la sesión ya no es válida', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(statusCode: 401, message: 'No autorizado.');
      final useCase = ListarSolicitudesUseCase(repo);

      expect(() => useCase.execute(), throwsA(isA<ApiException>()));
    });
  });
}
