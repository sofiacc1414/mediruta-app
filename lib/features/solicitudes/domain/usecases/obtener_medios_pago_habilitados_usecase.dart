import '../entities/medios_pago_habilitados.dart';
import '../repositories/solicitud_repository.dart';

/// Módulo 4 — qué medios de pago mostrar en el checkout (toggles del
/// panel admin).
class ObtenerMediosPagoHabilitadosUseCase {
  const ObtenerMediosPagoHabilitadosUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<MediosPagoHabilitados> execute() {
    return _repository.obtenerMediosPagoHabilitados();
  }
}
