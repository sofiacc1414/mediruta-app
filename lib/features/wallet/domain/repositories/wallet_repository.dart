import '../entities/wallet_domiciliario.dart';

/// Módulo 3 — puerto del dominio de la billetera del Domiciliario. El
/// dominio no sabe que existe la API HTTP.
abstract class WalletRepository {
  Future<WalletDomiciliario> obtenerWallet();

  /// `desde`/`hasta` en formato "yyyy-MM-dd".
  Future<WalletDomiciliarioPeriodo> obtenerWalletPeriodo(
    String desde,
    String hasta,
  );
}
