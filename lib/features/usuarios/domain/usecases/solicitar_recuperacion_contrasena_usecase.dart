import '../repositories/usuario_repository.dart';

/// G05 (paso 1) de HU-01 — solicita el OTP de recuperación por correo.
/// La API responde el mismo mensaje genérico exista o no la cuenta
/// (anti-enumeración), así que esta capa nunca distingue ese caso.
class SolicitarRecuperacionContrasenaUseCase {
  const SolicitarRecuperacionContrasenaUseCase(this._repository);

  final UsuarioRepository _repository;

  Future<void> execute({required String correo}) {
    return _repository.solicitarRecuperacionContrasena(correo: correo);
  }
}
