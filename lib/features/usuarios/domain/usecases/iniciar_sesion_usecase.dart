import '../entities/usuario.dart';
import '../repositories/usuario_repository.dart';

/// G03/G04 de HU-01 — inicio de sesión.
class IniciarSesionUseCase {
  const IniciarSesionUseCase(this._repository);

  final UsuarioRepository _repository;

  Future<Usuario> execute({required String correo, required String password}) {
    return _repository.iniciarSesion(correo: correo, password: password);
  }
}
