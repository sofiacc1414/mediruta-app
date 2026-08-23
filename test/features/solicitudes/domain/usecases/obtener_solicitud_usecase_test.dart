import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/medicamento.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/solicitud.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/obtener_solicitud_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('ObtenerSolicitudUseCase', () {
    test('G03 — devuelve el detalle que resuelve el repositorio', () async {
      const solicitud = Solicitud(
        id: 'solicitud-uuid',
        estado: 'borrador',
        recetaUrl: 'https://firmada.test/receta.jpg',
        recetaFechaVencimiento: '2026-08-01',
        direccionEntrega: 'Calle 1 #2-3',
        creadoEn: '2026-08-20T10:00:00.000Z',
        enviadoEn: null,
        canceladoEn: null,
        cedulaUrl: 'https://firmada.test/cedula.jpg',
        medicamentos: [Medicamento(nombre: 'Acetaminofén')],
        historial: [],
      );
      final repo = FakeSolicitudRepository()..solicitudARetornar = solicitud;
      final useCase = ObtenerSolicitudUseCase(repo);

      final resultado = await useCase.execute('solicitud-uuid');

      expect(resultado, solicitud);
      expect(repo.ultimaLlamada, {'metodo': 'obtener', 'solicitudId': 'solicitud-uuid'});
    });

    test('propaga el error si no existe o no es del dueño', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(statusCode: 404, message: 'No encontrada.');
      final useCase = ObtenerSolicitudUseCase(repo);

      expect(() => useCase.execute('solicitud-uuid'), throwsA(isA<ApiException>()));
    });
  });
}
