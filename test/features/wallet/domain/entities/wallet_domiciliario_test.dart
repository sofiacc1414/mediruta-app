import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/wallet/domain/entities/wallet_domiciliario.dart';

void main() {
  group('WalletDomiciliario.fromJson', () {
    test('parsea todos los campos', () {
      final wallet = WalletDomiciliario.fromJson({
        'comisionAcumulada': 50000,
        'saldoCobrado': 30000,
        'saldoPendienteCobrar': 10000,
        'deudaEfectivo': 190000,
        'bloqueadoPorTope': true,
        'topeRecaudoEfectivo': 200000,
      });

      expect(wallet.comisionAcumulada, 50000);
      expect(wallet.saldoCobrado, 30000);
      expect(wallet.saldoPendienteCobrar, 10000);
      expect(wallet.deudaEfectivo, 190000);
      expect(wallet.bloqueadoPorTope, true);
      expect(wallet.topeRecaudoEfectivo, 200000);
    });
  });

  group('WalletDomiciliarioPeriodo.fromJson', () {
    test('parsea todos los campos', () {
      final periodo = WalletDomiciliarioPeriodo.fromJson({
        'cobradoEfectivoPeriodo': 15000,
        'pendienteTarjetaTransferenciaPeriodo': 8000,
        'deudaGeneradaEfectivoPeriodo': 20000,
        'liquidadoEnPeriodo': 5000,
        'balancePeriodo': 23000,
      });

      expect(periodo.cobradoEfectivoPeriodo, 15000);
      expect(periodo.pendienteTarjetaTransferenciaPeriodo, 8000);
      expect(periodo.deudaGeneradaEfectivoPeriodo, 20000);
      expect(periodo.liquidadoEnPeriodo, 5000);
      expect(periodo.balancePeriodo, 23000);
    });
  });
}
