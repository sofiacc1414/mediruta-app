import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/novedad_resumen.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/listar_novedades_solicitud_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('ListarNovedadesSolicitudUseCase', () {
    test('HU-07 (ronda 5) — delega en el repositorio y devuelve la lista tal cual', () async {
      final repo = FakeSolicitudRepository()
        ..novedadesSolicitudARetornar = const [
          NovedadResumen(
            id: 'novedad-uuid',
            tipo: 'edicion',
            detalle: 'Pedido corrección',
            origen: 'paciente',
            creadoEn: '2026-09-05T10:00:00.000Z',
            resuelta: true,
            accionEdicion: 'rechazada',
            datosPropuestos: {'medicamentos': []},
          ),
        ];
      final useCase = ListarNovedadesSolicitudUseCase(repo);

      final resultado = await useCase.execute('solicitud-uuid');

      expect(repo.ultimaLlamada, {
        'metodo': 'listarNovedadesSolicitud',
        'solicitudId': 'solicitud-uuid',
      });
      expect(resultado, repo.novedadesSolicitudARetornar);
    });

    test('propaga el error del repositorio', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(statusCode: 404, message: 'No encontrada.');
      final useCase = ListarNovedadesSolicitudUseCase(repo);

      expect(
        () => useCase.execute('solicitud-uuid'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('NovedadResumen.incluyeMedicamentosOReceta', () {
    test('true si datosPropuestos trae medicamentos', () {
      const novedad = NovedadResumen(
        id: 'x',
        tipo: 'edicion',
        detalle: 'x',
        origen: 'paciente',
        creadoEn: 'x',
        resuelta: true,
        accionEdicion: 'rechazada',
        datosPropuestos: {'medicamentos': []},
      );
      expect(novedad.incluyeMedicamentosOReceta, isTrue);
    });

    test('true si datosPropuestos trae recetaPath', () {
      const novedad = NovedadResumen(
        id: 'x',
        tipo: 'edicion',
        detalle: 'x',
        origen: 'paciente',
        creadoEn: 'x',
        resuelta: true,
        accionEdicion: 'rechazada',
        datosPropuestos: {'recetaPath': 'solicitud/x/receta_propuesta.jpg'},
      );
      expect(novedad.incluyeMedicamentosOReceta, isTrue);
    });

    test('false si datosPropuestos solo trae direcciones', () {
      const novedad = NovedadResumen(
        id: 'x',
        tipo: 'edicion',
        detalle: 'x',
        origen: 'paciente',
        creadoEn: 'x',
        resuelta: true,
        accionEdicion: 'rechazada',
        datosPropuestos: {'direccionEntrega': 'Calle 1', 'direccionFarmacia': null},
      );
      expect(novedad.incluyeMedicamentosOReceta, isFalse);
    });

    test('false si datosPropuestos es null', () {
      const novedad = NovedadResumen(
        id: 'x',
        tipo: 'pregunta',
        detalle: 'x',
        origen: 'paciente',
        creadoEn: 'x',
        resuelta: false,
        accionEdicion: null,
        datosPropuestos: null,
      );
      expect(novedad.incluyeMedicamentosOReceta, isFalse);
    });
  });
}
