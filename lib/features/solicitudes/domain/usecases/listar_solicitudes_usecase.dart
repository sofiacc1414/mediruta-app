import '../entities/solicitud_resumen.dart';
import '../repositories/solicitud_repository.dart';

/// G02 de HU-03 — "Mis solicitudes".
class ListarSolicitudesUseCase {
  const ListarSolicitudesUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<List<SolicitudResumen>> execute() {
    return _repository.listar();
  }
}
