import '../entities/pedido_historial.dart';
import '../repositories/solicitud_repository.dart';

/// "Mis pedidos" del Domiciliario.
class ListarHistorialPedidosUseCase {
  const ListarHistorialPedidosUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<List<PedidoHistorial>> execute() {
    return _repository.listarHistorialPedidos();
  }
}
