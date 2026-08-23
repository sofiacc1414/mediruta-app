import '../../domain/entities/datos_solicitud.dart';
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
  Future<void> enviar(String solicitudId) {
    return _datasource.enviar(solicitudId);
  }

  @override
  Future<void> cancelar(String solicitudId) {
    return _datasource.cancelar(solicitudId);
  }
}
