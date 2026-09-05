import '../entities/novedad_resumen.dart';
import '../repositories/solicitud_repository.dart';

/// HU-07 (ronda 5) — "mis reportes sobre este pedido", con su estado.
/// A diferencia de `Solicitud.novedadAbierta` (solo la última sin
/// resolver), esto trae todas — resueltas incluidas.
class ListarNovedadesSolicitudUseCase {
  const ListarNovedadesSolicitudUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<List<NovedadResumen>> execute(String solicitudId) {
    return _repository.listarNovedadesSolicitud(solicitudId);
  }
}
