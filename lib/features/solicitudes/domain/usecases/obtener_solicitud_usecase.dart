import '../entities/solicitud.dart';
import '../repositories/solicitud_repository.dart';

/// G03 de HU-03 — detalle + historial de estados.
class ObtenerSolicitudUseCase {
  const ObtenerSolicitudUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<Solicitud> execute(String solicitudId) {
    return _repository.obtener(solicitudId);
  }
}
