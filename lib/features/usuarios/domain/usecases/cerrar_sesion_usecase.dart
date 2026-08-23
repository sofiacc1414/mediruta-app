import '../repositories/usuario_repository.dart';

/// G07 de HU-01 — cierre de sesión.
class CerrarSesionUseCase {
  const CerrarSesionUseCase(this._repository);

  final UsuarioRepository _repository;

  Future<void> execute() {
    return _repository.cerrarSesion();
  }
}
