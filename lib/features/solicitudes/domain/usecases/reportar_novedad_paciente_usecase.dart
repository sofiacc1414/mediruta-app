import '../repositories/solicitud_repository.dart';

/// HU-07 (ronda 2) — el Paciente reporta un incidente sobre su propio
/// pedido (ej. "el domiciliario no contesta"). No toca el estado real
/// del pedido, igual que [ReportarNovedadUseCase] del lado Domiciliario.
class ReportarNovedadPacienteUseCase {
  const ReportarNovedadPacienteUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<void> execute(String solicitudId, String detalle) {
    return _repository.reportarNovedadPaciente(solicitudId, detalle);
  }
}
