import '../../domain/entities/calificacion.dart';
import '../../domain/repositories/calificacion_repository.dart';
import '../datasources/calificacion_remote_datasource.dart';

class CalificacionRepositoryImpl implements CalificacionRepository {
  const CalificacionRepositoryImpl(this._remoto);
  final CalificacionRemoteDatasource _remoto;

  @override
  Future<List<PedidoCalificacion>> listarPedidos() async {
    final filas = await _remoto.listarPedidos();
    return filas
        .map((fila) => PedidoCalificacion.fromJson(fila as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Calificacion> consultar(String pedidoId) async {
    return Calificacion.fromJson(await _remoto.consultar(pedidoId));
  }

  @override
  Future<Calificacion> crear({
    required String pedidoId,
    required int puntuacion,
    String? comentario,
  }) async {
    return Calificacion.fromJson(
      await _remoto.crear(
        pedidoId: pedidoId,
        puntuacion: puntuacion,
        comentario: comentario,
      ),
    );
  }

  @override
  Future<Calificacion> actualizar({
    required String pedidoId,
    required int puntuacion,
    String? comentario,
  }) async {
    return Calificacion.fromJson(
      await _remoto.actualizar(
        pedidoId: pedidoId,
        puntuacion: puntuacion,
        comentario: comentario,
      ),
    );
  }

  @override
  Future<void> retirar(String pedidoId) => _remoto.retirar(pedidoId);
}
