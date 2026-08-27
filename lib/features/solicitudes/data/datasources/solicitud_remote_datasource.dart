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

  Future<void> subirReceta({
    required String solicitudId,
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) {
    return _apiClient.postMultipart(
      '/solicitudes/$solicitudId/receta',
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      contentType: contentType,
      autenticado: true,
    );
  }

  Future<Map<String, dynamic>> enviar(String solicitudId) async {
    final respuesta = await _apiClient.post(
      '/solicitudes/$solicitudId/enviar',
      autenticado: true,
    );
    return respuesta as Map<String, dynamic>;
  }

  Future<void> cancelar(String solicitudId) {
    return _apiClient.post('/solicitudes/$solicitudId/cancelar', autenticado: true);
  }

  /// HU-07 (ronda 2) — reportar novedad del lado Paciente, distinto del
  /// endpoint del Domiciliario (`/pedidos/:id/novedad`, más abajo).
  Future<void> reportarNovedadPaciente(String solicitudId, String detalle) {
    return _apiClient.post(
      '/solicitudes/$solicitudId/novedad',
      body: {'detalle': detalle},
      autenticado: true,
    );
  }

  // --- Domiciliario (HU-09/HU-07) ---

  Future<List<dynamic>> listarPedidosDisponibles() async {
    final respuesta = await _apiClient.get('/pedidos/disponibles', autenticado: true);
    return respuesta as List<dynamic>;
  }

  Future<void> aceptarPedido(String solicitudId) {
    return _apiClient.post('/pedidos/$solicitudId/aceptar', autenticado: true);
  }

  Future<void> marcarMedicamentosRecogidos(String solicitudId) {
    return _apiClient.post('/pedidos/$solicitudId/recogido', autenticado: true);
  }

  Future<void> iniciarEntrega(String solicitudId) {
    return _apiClient.post('/pedidos/$solicitudId/iniciar-entrega', autenticado: true);
  }

  Future<void> marcarEnSitio(String solicitudId) {
    return _apiClient.post('/pedidos/$solicitudId/en-sitio', autenticado: true);
  }

  Future<void> entregarPedido(String solicitudId, String codigo) {
    return _apiClient.post(
      '/pedidos/$solicitudId/entregar',
      body: {'codigo': codigo},
      autenticado: true,
    );
  }

  Future<void> reportarNovedad(String solicitudId, String detalle) {
    return _apiClient.post(
      '/pedidos/$solicitudId/novedad',
      body: {'detalle': detalle},
      autenticado: true,
    );
  }

  /// `null` en el cuerpo (200 sin JSON) si no tiene ningún pedido activo.
  Future<Map<String, dynamic>?> obtenerPedidoActivo() async {
    final respuesta = await _apiClient.get('/pedidos/mi-activo', autenticado: true);
    return respuesta as Map<String, dynamic>?;
  }

  Future<List<dynamic>> listarHistorialPedidos() async {
    final respuesta = await _apiClient.get('/pedidos/historial', autenticado: true);
    return respuesta as List<dynamic>;
  }

  /// HU-07/HU-09 — cédula del Paciente (ambos lados), para mostrar en
  /// la farmacia al reclamar el medicamento. La API solo la devuelve
  /// mientras el pedido está `asignado_en_camino_farmacia` (404 fuera
  /// de esa ventana, ver `ObtenerDocumentosPacienteParaRecogerUseCase`
  /// del lado de la API).
  Future<Map<String, dynamic>> obtenerDocumentosPacienteParaRecoger(
    String solicitudId,
  ) async {
    final respuesta = await _apiClient.get(
      '/pedidos/$solicitudId/documentos-paciente',
      autenticado: true,
    );
    return respuesta as Map<String, dynamic>;
  }
}
