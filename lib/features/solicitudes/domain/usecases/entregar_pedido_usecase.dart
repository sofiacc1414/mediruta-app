import '../repositories/solicitud_repository.dart';

/// HU-07 — cierra el pedido con el código de 6 que dice el paciente.
/// Si no coincide, la API responde `400`, propagado como `ApiException`.
class EntregarPedidoUseCase {
  const EntregarPedidoUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<void> execute(String solicitudId, String codigo) {
    return _repository.entregarPedido(solicitudId, codigo);
  }
}
