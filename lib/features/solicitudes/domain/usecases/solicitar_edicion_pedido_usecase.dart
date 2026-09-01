import '../repositories/solicitud_repository.dart';

/// HU-07 (ronda 3) — el Paciente pide corregir dirección de entrega y/o
/// de farmacia de un pedido ya enviado (no Borrador — eso se edita
/// directo con [ActualizarSolicitudUseCase]). Queda pendiente de que el
/// admin apruebe o rechace, no se aplica al instante.
class SolicitarEdicionPedidoUseCase {
  const SolicitarEdicionPedidoUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<void> execute(
    String solicitudId, {
    String? direccionEntrega,
    String? direccionFarmacia,
    String? detalle,
  }) {
    return _repository.solicitarEdicionPedido(
      solicitudId,
      direccionEntrega: direccionEntrega,
      direccionFarmacia: direccionFarmacia,
      detalle: detalle,
    );
  }
}
