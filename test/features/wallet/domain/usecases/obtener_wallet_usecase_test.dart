import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/wallet/domain/entities/wallet_domiciliario.dart';
import 'package:mediruta_app/features/wallet/domain/usecases/obtener_wallet_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_wallet_repository.dart';

void main() {
  group('ObtenerWalletUseCase', () {
    test('devuelve la wallet que resuelve el repositorio', () async {
      final repo = FakeWalletRepository()
        ..walletARetornar = const WalletDomiciliario(
          comisionAcumulada: 50000,
          saldoCobrado: 30000,
          saldoPendienteCobrar: 10000,
          deudaEfectivo: 190000,
          bloqueadoPorTope: true,
          topeRecaudoEfectivo: 200000,
        );
      final useCase = ObtenerWalletUseCase(repo);

      final resultado = await useCase.execute();

      expect(resultado.comisionAcumulada, 50000);
      expect(resultado.saldoCobrado, 30000);
      expect(resultado.saldoPendienteCobrar, 10000);
      expect(resultado.deudaEfectivo, 190000);
      expect(resultado.bloqueadoPorTope, true);
      expect(resultado.topeRecaudoEfectivo, 200000);
    });

    test('propaga el error del repositorio', () async {
      final repo = FakeWalletRepository()
        ..errorALanzar = const ApiException(statusCode: 401, message: 'No autorizado.');
      final useCase = ObtenerWalletUseCase(repo);

      expect(() => useCase.execute(), throwsA(isA<ApiException>()));
    });
  });
}
