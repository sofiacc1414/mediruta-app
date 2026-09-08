import '../entities/usuario.dart';
import '../repositories/usuario_repository.dart';

/// HU-05 (ronda 9) — reactiva la propia cuenta desactivada, ofrecida
/// desde el pop-up que sigue a un `ApiException.cuentaDesactivada` en
/// `IniciarSesionUseCase`.
class ReactivarCuentaUseCase {
  const ReactivarCuentaUseCase(this._repository);

  final UsuarioRepository _repository;

  Future<Usuario> execute({required String correo, required String password}) {
    return _repository.reactivarCuenta(correo: correo, password: password);
  }
}
