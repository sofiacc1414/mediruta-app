import '../entities/perfil.dart';
import '../repositories/perfil_repository.dart';

/// G02 de HU-02 — consulta el perfil propio.
class ObtenerPerfilUseCase {
  const ObtenerPerfilUseCase(this._repository);

  final PerfilRepository _repository;

  Future<Perfil> execute() {
    return _repository.obtenerPerfil();
  }
}
