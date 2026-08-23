import '../../../../shared/core/network/api_client.dart';
import '../../domain/entities/datos_solicitud.dart';

/// Traduce las operaciones de solicitudes (HU-03) a requests concretos
/// contra `mediruta-api` — única capa que conoce las rutas/forma del JSON.
class SolicitudRemoteDatasource {
  const SolicitudRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> crear(DatosSolicitud datos) async {
    final respuesta = await _apiClient.post(
      '/solicitudes',
      body: datos.toJson(),
      autenticado: true,
    );
    return respuesta as Map<String, dynamic>;
  }

  Future<List<dynamic>> listar() async {
    final respuesta = await _apiClient.get('/solicitudes', autenticado: true);
    return respuesta as List<dynamic>;
  }

  Future<Map<String, dynamic>> obtener(String solicitudId) async {
    final respuesta = await _apiClient.get('/solicitudes/$solicitudId', autenticado: true);
    return respuesta as Map<String, dynamic>;
  }

  Future<void> actualizar(String solicitudId, DatosSolicitud datos) {
    return _apiClient.patch(
      '/solicitudes/$solicitudId',
      body: datos.toJson(),
      autenticado: true,
    );
  }

  Future<void> enviar(String solicitudId) {
    return _apiClient.post('/solicitudes/$solicitudId/enviar', autenticado: true);
  }

  Future<void> cancelar(String solicitudId) {
    return _apiClient.post('/solicitudes/$solicitudId/cancelar', autenticado: true);
  }
}
