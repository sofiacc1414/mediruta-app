import '../entities/calificacion.dart';

abstract class CalificacionRepository {
  Future<List<PedidoCalificacion>> listarPedidos();
  Future<Calificacion> consultar(String pedidoId);
  Future<Calificacion> crear({
    required String pedidoId,
    required int puntuacion,
    String? comentario,
  });
  Future<Calificacion> actualizar({
    required String pedidoId,
    required int puntuacion,
    String? comentario,
  });
  Future<void> retirar(String pedidoId);
}
