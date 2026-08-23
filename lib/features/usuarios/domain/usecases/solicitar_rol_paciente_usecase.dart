import '../repositories/usuario_repository.dart';

/// Agrega el rol PACIENTE a la cuenta autenticada (p. ej. un
/// Domiciliario que no lo pidió al registrarse y cambió de idea).
/// Idempotente — pedirlo de nuevo no es un error.
class SolicitarRolPacienteUseCase {
  const SolicitarRolPacienteUseCase(this._repository);

  final UsuarioRepository _repository;

  Future<String> execute() {
    return _repository.solicitarRolPaciente();
  }
}
