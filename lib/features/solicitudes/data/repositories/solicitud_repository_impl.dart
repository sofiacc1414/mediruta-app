import '../../domain/entities/datos_solicitud.dart';
import '../../domain/entities/pedido_activo.dart';
import '../../domain/entities/pedido_disponible.dart';
import '../../domain/entities/solicitud.dart';
import '../../domain/entities/solicitud_resumen.dart';
import '../../domain/repositories/solicitud_repository.dart';
import '../datasources/solicitud_remote_datasource.dart';

class SolicitudRepositoryImpl implements SolicitudRepository {
  const SolicitudRepositoryImpl(this._datasource);

  final SolicitudRemoteDatasource _datasource;

  @override
  Future<String> crear(DatosSolicitud datos) async {
    final respuesta = await _datasource.crear(datos);
    return respuesta['id'] as String;
  }

  @override
  Future<List<SolicitudResumen>> listar() async {
    final respuesta = await _datasource.listar();
    return respuesta
        .map((e) => SolicitudResumen.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Solicitud> obtener(String solicitudId) async {
    final respuesta = await _datasource.obtener(solicitudId);
    return Solicitud.fromJson(respuesta);
  }

  @override
  Future<void> actualizar(String solicitudId, DatosSolicitud datos) {
    return _datasource.actualizar(solicitudId, datos);
  }

  @override
  Future<void> subirReceta({
    required String solicitudId,
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) {
    return _datasource.subirReceta(
      solicitudId: solicitudId,
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      contentType: contentType,
    );
  }

  @override
  Future<String> enviar(String solicitudId) async {
    final respuesta = await _datasource.enviar(solicitudId);
    return respuesta['codigoPedido'] as String;
  }

  @override
  Future<void> cancelar(String solicitudId) {
    return _datasource.cancelar(solicitudId);
  }

  @override
  Future<List<PedidoDisponible>> listarPedidosDisponibles() async {
    final respuesta = await _datasource.listarPedidosDisponibles();
    return respuesta
        .map((e) => PedidoDisponible.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> aceptarPedido(String solicitudId) {
    return _datasource.aceptarPedido(solicitudId);
  }

  @override
  Future<void> marcarMedicamentosRecogidos(String solicitudId) {
    return _datasource.marcarMedicamentosRecogidos(solicitudId);
  }

  @override
  Future<void> iniciarEntrega(String solicitudId) {
    return _datasource.iniciarEntrega(solicitudId);
  }

  @override
  Future<void> marcarEnSitio(String solicitudId) {
    return _datasource.marcarEnSitio(solicitudId);
  }

  @override
  Future<void> entregarPedido(String solicitudId, String codigo) {
    return _datasource.entregarPedido(solicitudId, codigo);
  }

  @override
  Future<void> reportarNovedad(String solicitudId, String detalle) {
    return _datasource.reportarNovedad(solicitudId, detalle);
  }

  @override
  Future<PedidoActivo?> obtenerPedidoActivo() async {
    final respuesta = await _datasource.obtenerPedidoActivo();
    return respuesta != null ? PedidoActivo.fromJson(respuesta) : null;
  }
}
