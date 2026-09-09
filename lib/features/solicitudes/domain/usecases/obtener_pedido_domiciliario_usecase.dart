import '../entities/pedido_activo.dart';
import '../repositories/solicitud_repository.dart';

/// Detalle de solo lectura de un pedido puntual del Historial del
/// Domiciliario (entregado o cancelado) — "Mis pedidos" era de solo
/// lectura sin detalle, tocar una fila del Historial no llevaba a
/// ningún lado.
class ObtenerPedidoDomiciliarioUseCase {
  const ObtenerPedidoDomiciliarioUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<PedidoActivo> execute(String solicitudId) {
    return _repository.obtenerPedidoPorId(solicitudId);
  }
}
