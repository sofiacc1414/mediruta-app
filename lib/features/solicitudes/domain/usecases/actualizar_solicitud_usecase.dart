import '../entities/datos_solicitud.dart';
import '../repositories/solicitud_repository.dart';

/// G04 de HU-03 — editar, solo mientras sigue en Borrador.
class ActualizarSolicitudUseCase {
  const ActualizarSolicitudUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<void> execute(String solicitudId, DatosSolicitud datos) {
    return _repository.actualizar(solicitudId, datos);
  }
}
