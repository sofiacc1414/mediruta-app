import '../entities/datos_solicitud.dart';
import '../repositories/solicitud_repository.dart';

/// G01 de HU-03 — crea la solicitud en estado Borrador.
class CrearSolicitudUseCase {
  const CrearSolicitudUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<String> execute(DatosSolicitud datos) {
    return _repository.crear(datos);
  }
}
