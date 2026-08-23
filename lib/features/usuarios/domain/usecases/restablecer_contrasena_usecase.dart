import '../repositories/usuario_repository.dart';

/// G05 (paso 2) de HU-01 — consume el OTP y fija una nueva contraseña.
class RestablecerContrasenaUseCase {
  const RestablecerContrasenaUseCase(this._repository);

  final UsuarioRepository _repository;

  Future<void> execute({
    required String correo,
    required String codigo,
    required String nuevaPassword,
  }) {
    return _repository.restablecerContrasena(
      correo: correo,
      codigo: codigo,
      nuevaPassword: nuevaPassword,
    );
  }
}
