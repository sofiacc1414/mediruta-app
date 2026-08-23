import '../repositories/usuario_repository.dart';

/// G06 de HU-01 — cambio de contraseña con sesión activa.
class CambiarContrasenaUseCase {
  const CambiarContrasenaUseCase(this._repository);

  final UsuarioRepository _repository;

  Future<void> execute({
    required String passwordActual,
    required String nuevaPassword,
  }) {
    return _repository.cambiarContrasena(
      passwordActual: passwordActual,
      nuevaPassword: nuevaPassword,
    );
  }
}
