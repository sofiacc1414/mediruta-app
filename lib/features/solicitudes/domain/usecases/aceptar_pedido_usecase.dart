import '../repositories/solicitud_repository.dart';

/// HU-09 — acepta un pedido del pool. Puede fallar con `409` si otro
/// domiciliario lo aceptó primero, o si ya tenés un pedido activo — se
/// propaga como `ApiException`, la pantalla decide cómo mostrarlo.
class AceptarPedidoUseCase {
  const AceptarPedidoUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<void> execute(String solicitudId) {
    return _repository.aceptarPedido(solicitudId);
  }
}
