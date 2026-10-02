import '../repositories/calificacion_repository.dart';

class RetirarCalificacionUseCase {
  const RetirarCalificacionUseCase(this._repositorio);
  final CalificacionRepository _repositorio;

  Future<void> execute(String pedidoId) => _repositorio.retirar(pedidoId);
}
