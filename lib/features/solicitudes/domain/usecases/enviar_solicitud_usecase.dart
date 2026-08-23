import '../repositories/solicitud_repository.dart';

/// G05 de HU-03 — envía a revisión. La API rechaza (422) si falta algún
/// obligatorio; la UI ya deshabilita el botón antes de eso calculando lo
/// mismo del lado del cliente (`DatosSolicitud.calcularFaltantes`).
/// Devuelve el código de pedido recién generado (`MR-000001`, ...).
class EnviarSolicitudUseCase {
  const EnviarSolicitudUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<String> execute(String solicitudId) {
    return _repository.enviar(solicitudId);
  }
}
