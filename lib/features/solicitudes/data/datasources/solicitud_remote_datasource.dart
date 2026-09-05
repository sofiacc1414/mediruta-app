import '../../../../shared/core/network/api_client.dart';
import '../../domain/entities/datos_solicitud.dart';
import '../../domain/entities/medicamento.dart';

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

  /// HU-07 (ronda 3/4) — pide corregir dirección de entrega, de
  /// farmacia y/o medicamentos de un pedido ya enviado. Solo manda los
  /// campos no nulos. Devuelve el id de la novedad creada (lo necesita
  /// [adjuntarRecetaPropuestaEdicion] si además se propone una foto).
  Future<String> solicitarEdicionPedido(
    String solicitudId, {
    String? direccionEntrega,
    String? direccionFarmacia,
    String? detalle,
    List<Medicamento>? medicamentos,
    bool incluyeReceta = false,
  }) async {
    final respuesta = await _apiClient.post(
      '/solicitudes/$solicitudId/solicitar-edicion',
      body: {
        if (direccionEntrega != null) 'direccionEntrega': direccionEntrega,
        if (direccionFarmacia != null) 'direccionFarmacia': direccionFarmacia,
        if (detalle != null) 'detalle': detalle,
        if (medicamentos != null) 'medicamentos': medicamentos.map((m) => m.toJson()).toList(),
        if (incluyeReceta) 'incluyeReceta': true,
      },
      autenticado: true,
    );
    return (respuesta as Map<String, dynamic>)['id'] as String;
  }

  /// HU-07 (ronda 4) — adjunta la foto de receta propuesta a una
  /// novedad de edición ya creada.
  Future<void> adjuntarRecetaPropuestaEdicion({
    required String solicitudId,
    required String novedadId,
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) {
    return _apiClient.postMultipart(
      '/solicitudes/$solicitudId/solicitar-edicion/$novedadId/receta',
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      contentType: contentType,
      autenticado: true,
    );
  }

  /// HU-07 (ronda 3) — reporta que el código de entrega no se generó o
  /// no se ve en la app.
  Future<void> reportarCodigoNoGenerado(String solicitudId, {String? detalle}) {
    return _apiClient.post(
      '/solicitudes/$solicitudId/reportar-codigo-no-generado',
      body: {if (detalle != null) 'detalle': detalle},
      autenticado: true,
    );
  }

  /// HU-07 (ronda 5) — todas las novedades del pedido, resueltas o no.
  Future<List<dynamic>> listarNovedadesSolicitud(String solicitudId) async {
    final respuesta = await _apiClient.get(
      '/solicitudes/$solicitudId/novedades',
      autenticado: true,
    );
    return respuesta as List<dynamic>;
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
