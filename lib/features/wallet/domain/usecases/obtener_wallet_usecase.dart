import '../entities/wallet_domiciliario.dart';
import '../repositories/wallet_repository.dart';

/// Módulo 3 — el Domiciliario ve su propio saldo disponible y la deuda
/// de efectivo que debe liquidar antes de que lo bloqueen (o ya lo
/// bloqueó, ver `bloqueadoPorTope`).
class ObtenerWalletUseCase {
  const ObtenerWalletUseCase(this._repository);

  final WalletRepository _repository;

  Future<WalletDomiciliario> execute() {
    return _repository.obtenerWallet();
  }
}
