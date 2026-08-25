import '../repositories/solicitud_repository.dart';

/// HU-07 — el Domiciliario reporta un incidente sin tocar el estado real
/// del pedido (convive con el paso en curso).
class ReportarNovedadUseCase {
  const ReportarNovedadUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<void> execute(String solicitudId, String detalle) {
    return _repository.reportarNovedad(solicitudId, detalle);
  }
}
