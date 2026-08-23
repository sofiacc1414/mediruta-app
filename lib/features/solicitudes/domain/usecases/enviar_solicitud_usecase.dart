import '../repositories/solicitud_repository.dart';

/// G05 de HU-03 — envía a revisión. La API rechaza (422) si falta algún
/// obligatorio; la UI ya deshabilita el botón antes de eso calculando lo
/// mismo del lado del cliente (`DatosSolicitud.calcularFaltantes`).
class EnviarSolicitudUseCase {
  const EnviarSolicitudUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<void> execute(String solicitudId) {
    return _repository.enviar(solicitudId);
  }
}
