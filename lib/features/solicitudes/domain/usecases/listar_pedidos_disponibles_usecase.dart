import '../entities/pedido_disponible.dart';
import '../repositories/solicitud_repository.dart';

/// HU-09 — pool de pedidos disponibles para el Domiciliario, ordenado
/// por distancia real a la farmacia.
class ListarPedidosDisponiblesUseCase {
  const ListarPedidosDisponiblesUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<List<PedidoDisponible>> execute() {
    return _repository.listarPedidosDisponibles();
  }
}
