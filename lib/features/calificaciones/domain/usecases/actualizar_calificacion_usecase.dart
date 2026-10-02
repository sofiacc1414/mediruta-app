import '../entities/calificacion.dart';
import '../repositories/calificacion_repository.dart';

class ActualizarCalificacionUseCase {
  const ActualizarCalificacionUseCase(this._repositorio);
  final CalificacionRepository _repositorio;

  Future<Calificacion> execute({
    required String pedidoId,
    required int puntuacion,
    String? comentario,
  }) {
    return _repositorio.actualizar(
      pedidoId: pedidoId,
      puntuacion: puntuacion,
      comentario: comentario,
    );
  }
}
