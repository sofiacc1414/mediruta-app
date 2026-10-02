import '../../../../shared/core/network/api_client.dart';
import '../../../../shared/core/network/api_exception.dart';

/// Arma la fila que espera `PedidoCalificacion` a partir del resumen de
/// `GET /solicitudes`. Ese listado no trae medicamentos ni si ya hay
/// calificación; esos dos datos se completan aparte.
Map<String, dynamic> pedidoCalificacionDesdeSolicitud(
  Map<String, dynamic> fila, {
  required int cantidadMedicamentos,
  required bool tieneCalificacionActiva,
}) {
  return {
    'id': fila['id'],
    'codigoPedido': fila['codigoPedido'],
    'estado': fila['estado'],
    'creadoEn': fila['creadoEn'],
    'cantidadMedicamentos': cantidadMedicamentos,
    'tieneCalificacionActiva': tieneCalificacionActiva,
  };
}

class CalificacionRemoteDatasource {
  const CalificacionRemoteDatasource(this._api);
  final ApiClient _api;

  /// Pedidos del paciente. No existe `GET /pedidos` ni un historial de
  /// paciente en `/pedidos/historial` (ese es del domiciliario). El
  /// listado propio ya es `GET /solicitudes`.
  Future<List<dynamic>> listarPedidos() async {
    final respuesta = await _api.get('/solicitudes', autenticado: true);
    final filas = (respuesta as List<dynamic>)
        .map((fila) => Map<String, dynamic>.from(fila as Map))
        .toList();
    return Future.wait(filas.map(_completar));
  }

  Future<Map<String, dynamic>> _completar(Map<String, dynamic> fila) async {
    final id = fila['id'] as String;
    final estado = fila['estado'] as String? ?? '';
    final medicamentos = fila['medicamentos'];
    var cantidad = medicamentos is List ? medicamentos.length : 0;
    var tieneCalificacion = false;

    if (estado == 'entregado') {
      try {
        await consultar(id);
        tieneCalificacion = true;
      } on ApiException catch (error) {
        if (error.statusCode != 404) rethrow;
      }
    }

    if (cantidad == 0) {
      try {
        final detalle = await _api.get('/solicitudes/$id', autenticado: true);
        final lista = (detalle as Map)['medicamentos'];
        if (lista is List) cantidad = lista.length;
      } on ApiException {
        cantidad = 0;
      }
    }

    return pedidoCalificacionDesdeSolicitud(
      fila,
      cantidadMedicamentos: cantidad,
      tieneCalificacionActiva: tieneCalificacion,
    );
  }

  Future<Map<String, dynamic>> consultar(String pedidoId) async {
    final respuesta = await _api.get(
      '/pedidos/$pedidoId/calificacion',
      autenticado: true,
    );
    return respuesta as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> crear({
    required String pedidoId,
    required int puntuacion,
    String? comentario,
  }) async {
    final respuesta = await _api.post(
      '/pedidos/$pedidoId/calificacion',
      body: _cuerpo(puntuacion, comentario),
      autenticado: true,
    );
    return respuesta as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> actualizar({
    required String pedidoId,
    required int puntuacion,
    String? comentario,
  }) async {
    final respuesta = await _api.patch(
      '/pedidos/$pedidoId/calificacion',
      body: _cuerpo(puntuacion, comentario),
      autenticado: true,
    );
    return respuesta as Map<String, dynamic>;
  }

  Future<void> retirar(String pedidoId) {
    return _api.delete('/pedidos/$pedidoId/calificacion', autenticado: true);
  }

  Map<String, dynamic> _cuerpo(int puntuacion, String? comentario) {
    final texto = comentario?.trim();
    return {
      'puntuacion': puntuacion,
      if (texto != null && texto.isNotEmpty) 'comentario': texto,
    };
  }
}
