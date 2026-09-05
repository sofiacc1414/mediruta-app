import '../entities/medicamento.dart';
import '../repositories/solicitud_repository.dart';

/// HU-07 (ronda 3/4) — el Paciente pide corregir dirección de entrega,
/// de farmacia y/o medicamentos de un pedido ya enviado (no Borrador —
/// eso se edita directo con [ActualizarSolicitudUseCase]). Si además
/// va a proponer una foto de receta nueva, pásese `incluyeReceta: true`
/// y luego adjúntese con [AdjuntarRecetaPropuestaEdicionUseCase] usando
/// el id que devuelve esta llamada. Queda pendiente de que el admin
/// apruebe o rechace, no se aplica al instante.
class SolicitarEdicionPedidoUseCase {
  const SolicitarEdicionPedidoUseCase(this._repository);

  final SolicitudRepository _repository;

  /// Devuelve el id de la novedad creada.
  Future<String> execute(
    String solicitudId, {
    String? direccionEntrega,
    String? direccionFarmacia,
    String? detalle,
    List<Medicamento>? medicamentos,
    bool incluyeReceta = false,
  }) {
    return _repository.solicitarEdicionPedido(
      solicitudId,
      direccionEntrega: direccionEntrega,
      direccionFarmacia: direccionFarmacia,
      detalle: detalle,
      medicamentos: medicamentos,
      incluyeReceta: incluyeReceta,
    );
  }
}
