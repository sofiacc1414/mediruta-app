import '../entities/calificacion.dart';
import '../repositories/calificacion_repository.dart';

class ConsultarCalificacionUseCase {
  const ConsultarCalificacionUseCase(this._repositorio);
  final CalificacionRepository _repositorio;

  Future<Calificacion> execute(String pedidoId) => _repositorio.consultar(pedidoId);
}
