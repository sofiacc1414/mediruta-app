import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/calificaciones/domain/entities/calificacion.dart';
import 'package:mediruta_app/features/calificaciones/domain/repositories/calificacion_repository.dart';
import 'package:mediruta_app/features/calificaciones/domain/usecases/crear_calificacion_usecase.dart';
import 'package:mediruta_app/features/calificaciones/domain/usecases/listar_pedidos_calificacion_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

class _Repo implements CalificacionRepository {
  Object? error;
  Calificacion? creada;
  List<PedidoCalificacion> lista = const [];

  @override
  Future<Calificacion> actualizar({
    required String pedidoId,
    required int puntuacion,
    String? comentario,
  }) => throw UnimplementedError();

  @override
  Future<Calificacion> consultar(String pedidoId) => throw UnimplementedError();

  @override
  Future<Calificacion> crear({
    required String pedidoId,
    required int puntuacion,
    String? comentario,
  }) async {
    if (error != null) throw error!;
    return creada!;
  }

  @override
  Future<List<PedidoCalificacion>> listarPedidos() async {
    if (error != null) throw error!;
    return lista;
  }

  @override
  Future<void> retirar(String pedidoId) => throw UnimplementedError();
}

void main() {
  test('lista vacía cuando no hay pedidos', () async {
    final repo = _Repo();
    final casos = ListarPedidosCalificacionUseCase(repo);
    expect(await casos.execute(), isEmpty);
  });

  test('propaga el error de la API', () async {
    final repo = _Repo()
      ..error = const ApiException(statusCode: 403, message: 'No puedes calificar este pedido.');
    final casos = CrearCalificacionUseCase(repo);
    expect(
      () => casos.execute(pedidoId: 'p', puntuacion: 5),
      throwsA(isA<ApiException>()),
    );
  });
}
