import '../repositories/solicitud_repository.dart';

/// HU-07 — el Domiciliario sale hacia la dirección del paciente.
class IniciarEntregaUseCase {
  const IniciarEntregaUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<void> execute(String solicitudId) {
    return _repository.iniciarEntrega(solicitudId);
  }
}
