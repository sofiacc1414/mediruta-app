import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/wallet/domain/entities/wallet_domiciliario.dart';
import 'package:mediruta_app/features/wallet/domain/usecases/obtener_wallet_periodo_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_wallet_repository.dart';

void main() {
  group('ObtenerWalletPeriodoUseCase', () {
    test('devuelve el balance del periodo que resuelve el repositorio', () async {
      final repo = FakeWalletRepository()
        ..periodoARetornar = const WalletDomiciliarioPeriodo(
          cobradoEfectivoPeriodo: 15000,
          pendienteTarjetaTransferenciaPeriodo: 8000,
          deudaGeneradaEfectivoPeriodo: 20000,
          liquidadoEnPeriodo: 5000,
          balancePeriodo: 23000,
        );
      final useCase = ObtenerWalletPeriodoUseCase(repo);

      final resultado = await useCase.execute('2026-10-01', '2026-10-31');

      expect(resultado.balancePeriodo, 23000);
      expect(resultado.cobradoEfectivoPeriodo, 15000);
      expect(resultado.pendienteTarjetaTransferenciaPeriodo, 8000);
    });

    test('propaga el error del repositorio', () async {
      final repo = FakeWalletRepository()
        ..errorALanzar = const ApiException(statusCode: 401, message: 'No autorizado.');
      final useCase = ObtenerWalletPeriodoUseCase(repo);

      expect(
        () => useCase.execute('2026-10-01', '2026-10-31'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
