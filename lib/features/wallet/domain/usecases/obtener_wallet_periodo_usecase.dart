import '../entities/wallet_domiciliario.dart';
import '../repositories/wallet_repository.dart';

/// Módulo 3 — balance del Domiciliario recalculado para el rango de
/// fechas elegido (no es el acumulado histórico).
class ObtenerWalletPeriodoUseCase {
  const ObtenerWalletPeriodoUseCase(this._repository);

  final WalletRepository _repository;

  Future<WalletDomiciliarioPeriodo> execute(String desde, String hasta) {
    return _repository.obtenerWalletPeriodo(desde, hasta);
  }
}
