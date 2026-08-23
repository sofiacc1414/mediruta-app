import '../entities/usuario.dart';
import '../repositories/usuario_repository.dart';

/// GET /auth/me — usado al arrancar la app (restaurar sesión) y como
/// guard antes de mostrar pantallas que requieren identidad.
class ObtenerSesionActualUseCase {
  const ObtenerSesionActualUseCase(this._repository);

  final UsuarioRepository _repository;

  Future<Usuario> execute() {
    return _repository.obtenerSesionActual();
  }
}
