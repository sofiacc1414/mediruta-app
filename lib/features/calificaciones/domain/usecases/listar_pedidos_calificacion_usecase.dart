import '../entities/calificacion.dart';
import '../repositories/calificacion_repository.dart';

class ListarPedidosCalificacionUseCase {
  const ListarPedidosCalificacionUseCase(this._repositorio);
  final CalificacionRepository _repositorio;

  Future<List<PedidoCalificacion>> execute() => _repositorio.listarPedidos();
}
