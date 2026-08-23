import '../repositories/solicitud_repository.dart';

/// G06 de HU-03 — cancela la solicitud.
class CancelarSolicitudUseCase {
  const CancelarSolicitudUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<void> execute(String solicitudId) {
    return _repository.cancelar(solicitudId);
  }
}
