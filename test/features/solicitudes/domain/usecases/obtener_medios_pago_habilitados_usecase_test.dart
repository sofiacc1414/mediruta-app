import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/medios_pago_habilitados.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/obtener_medios_pago_habilitados_usecase.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('ObtenerMediosPagoHabilitadosUseCase', () {
    test('devuelve los medios que resuelve el repositorio', () async {
      final repo = FakeSolicitudRepository()
        ..mediosPagoARetornar = const MediosPagoHabilitados(
          pagoEfectivoHabilitado: true,
          pagoTarjetaHabilitado: true,
          pagoTransferenciaHabilitado: false,
        );
      final useCase = ObtenerMediosPagoHabilitadosUseCase(repo);

      final resultado = await useCase.execute();

      expect(resultado.pagoEfectivoHabilitado, true);
      expect(resultado.pagoTarjetaHabilitado, true);
      expect(resultado.pagoTransferenciaHabilitado, false);
    });
  });
}
