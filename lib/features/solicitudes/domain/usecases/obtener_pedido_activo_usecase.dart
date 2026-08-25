import '../entities/pedido_activo.dart';
import '../repositories/solicitud_repository.dart';

/// HU-09/HU-07 — "Mi pedido activo": `null` si el Domiciliario no tiene
/// ninguno en curso.
class ObtenerPedidoActivoUseCase {
  const ObtenerPedidoActivoUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<PedidoActivo?> execute() {
    return _repository.obtenerPedidoActivo();
  }
}
