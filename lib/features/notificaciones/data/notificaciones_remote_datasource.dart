import '../../../shared/core/network/api_client.dart';
import '../domain/notificacion.dart';

class NotificacionesRemoteDatasource {
  const NotificacionesRemoteDatasource(this._api);

  final ApiClient _api;

  Future<List<Notificacion>> listar() async {
    final respuesta = await _api.get('/notificaciones', autenticado: true);
    final lista = respuesta as List<dynamic>;
    return lista
        .map((item) => Notificacion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> marcarLeida(String id) async {
    await _api.post('/notificaciones/$id/leida', autenticado: true);
  }
}
