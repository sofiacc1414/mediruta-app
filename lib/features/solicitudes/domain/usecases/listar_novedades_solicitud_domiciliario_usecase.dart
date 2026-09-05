import '../entities/novedad_resumen.dart';
import '../repositories/solicitud_repository.dart';

/// HU-07/HU-09 (ronda 7) — equivalente de [ListarNovedadesSolicitudUseCase]
/// para el tab "Novedades" del Domiciliario.
class ListarNovedadesSolicitudDomiciliarioUseCase {
  const ListarNovedadesSolicitudDomiciliarioUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<List<NovedadResumen>> execute(String solicitudId) {
    return _repository.listarNovedadesSolicitudDomiciliario(solicitudId);
  }
}
