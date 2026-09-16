import '../entities/precio_pedido.dart';
import '../repositories/solicitud_repository.dart';

/// G05 de HU-03 — envía a revisión. La API rechaza (422) si falta algún
/// obligatorio; la UI ya deshabilita el botón antes de eso calculando lo
/// mismo del lado del cliente (`DatosSolicitud.calcularFaltantes`).
/// Devuelve el código de pedido recién generado (`MR-000001`, ...).
///
/// Ronda 14 — `farmaciaVerificada`/`entregaVerificada`: si el estimado
/// en vivo ya confirmó una dirección, se mandan sus coordenadas acá
/// para que el envío no tenga que volver a geocodificarla (ver doc
/// del lado de la API en `EnviarSolicitudUseCase`).
class EnviarSolicitudUseCase {
  const EnviarSolicitudUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<String> execute(
    String solicitudId, {
    VerificacionDireccionPrevia? farmaciaVerificada,
    VerificacionDireccionPrevia? entregaVerificada,
  }) {
    return _repository.enviar(
      solicitudId,
      farmaciaVerificada: farmaciaVerificada,
      entregaVerificada: entregaVerificada,
    );
  }
}
