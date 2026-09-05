import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/medicamento.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/solicitar_edicion_pedido_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('SolicitarEdicionPedidoUseCase', () {
    test('HU-07 (ronda 3) — delega los campos propuestos en el repositorio', () async {
      final repo = FakeSolicitudRepository();
      final useCase = SolicitarEdicionPedidoUseCase(repo);

      await useCase.execute(
        'solicitud-uuid',
        direccionEntrega: 'Calle nueva 123',
        detalle: 'Me mudé',
      );

      expect(repo.ultimaLlamada, {
        'metodo': 'solicitarEdicionPedido',
        'solicitudId': 'solicitud-uuid',
        'direccionEntrega': 'Calle nueva 123',
        'direccionFarmacia': null,
        'detalle': 'Me mudé',
        'medicamentos': null,
        'incluyeReceta': false,
      });
    });

    test('HU-07 (ronda 4) — delega medicamentos e incluyeReceta, y devuelve el id de la novedad', () async {
      final repo = FakeSolicitudRepository()..novedadIdARetornar = 'novedad-nueva-uuid';
      final useCase = SolicitarEdicionPedidoUseCase(repo);
      const medicamentos = [Medicamento(nombre: 'Ibuprofeno')];

      final id = await useCase.execute(
        'solicitud-uuid',
        medicamentos: medicamentos,
        incluyeReceta: true,
      );

      expect(id, 'novedad-nueva-uuid');
      expect(repo.ultimaLlamada, {
        'metodo': 'solicitarEdicionPedido',
        'solicitudId': 'solicitud-uuid',
        'direccionEntrega': null,
        'direccionFarmacia': null,
        'detalle': null,
        'medicamentos': medicamentos,
        'incluyeReceta': true,
      });
    });

    test('propaga el error si el pedido no admite edición', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(statusCode: 404, message: 'No encontrada.');
      final useCase = SolicitarEdicionPedidoUseCase(repo);

      expect(
        () => useCase.execute('solicitud-uuid', direccionEntrega: 'Calle nueva'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
