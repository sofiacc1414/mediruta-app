import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/novedad_resumen.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/listar_novedades_solicitud_domiciliario_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('ListarNovedadesSolicitudDomiciliarioUseCase', () {
    test('HU-07/HU-09 (ronda 7) — delega en el repositorio y devuelve la lista tal cual', () async {
      final repo = FakeSolicitudRepository()
        ..novedadesSolicitudARetornar = const [
          NovedadResumen(
            id: 'novedad-uuid',
            tipo: 'pregunta',
            detalle: 'Faltó un medicamento',
            origen: 'domiciliario',
            creadoEn: '2026-09-08T10:00:00.000Z',
            resuelta: false,
            accionEdicion: null,
            datosPropuestos: null,
          ),
        ];
      final useCase = ListarNovedadesSolicitudDomiciliarioUseCase(repo);

      final resultado = await useCase.execute('solicitud-uuid');

      expect(repo.ultimaLlamada, {
        'metodo': 'listarNovedadesSolicitudDomiciliario',
        'solicitudId': 'solicitud-uuid',
      });
      expect(resultado, repo.novedadesSolicitudARetornar);
    });

    test('propaga el error del repositorio', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(statusCode: 404, message: 'No encontrada.');
      final useCase = ListarNovedadesSolicitudDomiciliarioUseCase(repo);

      expect(
        () => useCase.execute('solicitud-uuid'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
