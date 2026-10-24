import '../../../../shared/core/network/api_client.dart';

/// Traduce las operaciones de la billetera (Módulo 3) a requests
/// concretos contra `mediruta-api`.
class WalletRemoteDatasource {
  const WalletRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> obtenerWallet() async {
    final respuesta = await _apiClient.get('/wallet', autenticado: true);
    return respuesta as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> obtenerWalletPeriodo(
    String desde,
    String hasta,
  ) async {
    final respuesta = await _apiClient.get(
      '/wallet/periodo?desde=$desde&hasta=$hasta',
      autenticado: true,
    );
    return respuesta as Map<String, dynamic>;
  }
}
