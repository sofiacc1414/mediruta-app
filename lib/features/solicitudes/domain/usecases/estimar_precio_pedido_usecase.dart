import '../entities/precio_pedido.dart';
import '../repositories/solicitud_repository.dart';

/// Estimado en vivo mientras el Paciente arma el borrador, antes de
/// enviar (NuevaSolicitudScreen) — ver doc del lado de la API en
/// `EstimarPrecioPedidoUseCase`.
class EstimarPrecioPedidoUseCase {
  const EstimarPrecioPedidoUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<PrecioPedido> execute({
    required String direccionFarmacia,
    required String direccionEntrega,
  }) {
    return _repository.estimarPrecio(
      direccionFarmacia: direccionFarmacia,
      direccionEntrega: direccionEntrega,
    );
  }
}
