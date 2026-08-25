import '../repositories/solicitud_repository.dart';

/// HU-07 — el Domiciliario confirma que retiró los medicamentos.
class MarcarMedicamentosRecogidosUseCase {
  const MarcarMedicamentosRecogidosUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<void> execute(String solicitudId) {
    return _repository.marcarMedicamentosRecogidos(solicitudId);
  }
}
