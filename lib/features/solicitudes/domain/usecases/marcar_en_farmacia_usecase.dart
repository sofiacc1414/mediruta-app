import '../repositories/solicitud_repository.dart';

/// El domiciliario confirma que llegó a la farmacia. Recién ahí la API
/// permite ver la cédula del paciente.
class MarcarEnFarmaciaUseCase {
  const MarcarEnFarmaciaUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<void> execute(String solicitudId) {
    return _repository.marcarEnFarmacia(solicitudId);
  }
}
