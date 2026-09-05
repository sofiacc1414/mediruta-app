import '../repositories/solicitud_repository.dart';

/// HU-07 (ronda 4) — adjunta una foto de receta propuesta a una
/// novedad de edición ya creada (ver [SolicitarEdicionPedidoUseCase]).
/// No toca la receta vigente del pedido — eso solo pasa si el admin
/// aprueba la novedad.
class AdjuntarRecetaPropuestaEdicionUseCase {
  const AdjuntarRecetaPropuestaEdicionUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<void> execute({
    required String solicitudId,
    required String novedadId,
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) {
    return _repository.adjuntarRecetaPropuestaEdicion(
      solicitudId: solicitudId,
      novedadId: novedadId,
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      contentType: contentType,
    );
  }
}
