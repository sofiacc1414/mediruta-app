import '../entities/calificacion.dart';
import '../repositories/calificacion_repository.dart';

class CrearCalificacionUseCase {
  const CrearCalificacionUseCase(this._repositorio);
  final CalificacionRepository _repositorio;

  Future<Calificacion> execute({
    required String pedidoId,
    required int puntuacion,
    String? comentario,
  }) {
    return _repositorio.crear(
      pedidoId: pedidoId,
      puntuacion: puntuacion,
      comentario: comentario,
    );
  }
}
