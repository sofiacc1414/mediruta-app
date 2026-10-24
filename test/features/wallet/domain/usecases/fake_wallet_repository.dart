import 'package:mediruta_app/features/wallet/domain/entities/wallet_domiciliario.dart';
import 'package:mediruta_app/features/wallet/domain/repositories/wallet_repository.dart';

/// Fake escrito a mano del puerto `WalletRepository` — mismo espíritu
/// que `FakeSolicitudRepository`.
class FakeWalletRepository implements WalletRepository {
  Object? errorALanzar;
  WalletDomiciliario walletARetornar = const WalletDomiciliario(
    comisionAcumulada: 0,
    saldoCobrado: 0,
    saldoPendienteCobrar: 0,
    deudaEfectivo: 0,
    bloqueadoPorTope: false,
    topeRecaudoEfectivo: 200000,
  );
  WalletDomiciliarioPeriodo periodoARetornar = const WalletDomiciliarioPeriodo(
    cobradoEfectivoPeriodo: 0,
    pendienteTarjetaTransferenciaPeriodo: 0,
    deudaGeneradaEfectivoPeriodo: 0,
    liquidadoEnPeriodo: 0,
    balancePeriodo: 0,
  );

  @override
  Future<WalletDomiciliario> obtenerWallet() async {
    if (errorALanzar != null) throw errorALanzar!;
    return walletARetornar;
  }

  @override
  Future<WalletDomiciliarioPeriodo> obtenerWalletPeriodo(
    String desde,
    String hasta,
  ) async {
    if (errorALanzar != null) throw errorALanzar!;
    return periodoARetornar;
  }
}
