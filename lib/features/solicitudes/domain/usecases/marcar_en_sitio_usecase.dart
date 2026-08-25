import '../repositories/solicitud_repository.dart';

/// HU-07 — el Domiciliario confirma que llegó a la dirección del
/// paciente.
class MarcarEnSitioUseCase {
  const MarcarEnSitioUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<void> execute(String solicitudId) {
    return _repository.marcarEnSitio(solicitudId);
  }
}
