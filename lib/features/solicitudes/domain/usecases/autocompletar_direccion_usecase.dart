import '../entities/precio_pedido.dart';
import '../repositories/solicitud_repository.dart';

/// Ronda 13 — sugerencias mientras se escribe la dirección de
/// farmacia/entrega, no solo al perder el foco. Ver
/// `EstimarPrecioPedidoUseCase` para la confirmación/precio final.
class AutocompletarDireccionUseCase {
  const AutocompletarDireccionUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<List<CandidatoDireccion>> execute(String texto) {
    return _repository.autocompletarDireccion(texto);
  }
}
