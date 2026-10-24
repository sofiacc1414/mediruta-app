import '../../domain/entities/wallet_domiciliario.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._datasource);

  final WalletRemoteDatasource _datasource;

  @override
  Future<WalletDomiciliario> obtenerWallet() async {
    final respuesta = await _datasource.obtenerWallet();
    return WalletDomiciliario.fromJson(respuesta);
  }

  @override
  Future<WalletDomiciliarioPeriodo> obtenerWalletPeriodo(
    String desde,
    String hasta,
  ) async {
    final respuesta = await _datasource.obtenerWalletPeriodo(desde, hasta);
    return WalletDomiciliarioPeriodo.fromJson(respuesta);
  }
}
