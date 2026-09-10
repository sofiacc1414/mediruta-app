import '../repositories/perfil_repository.dart';

/// El Paciente autodeclara su nivel de copago en su perfil — sin
/// aprobación de un admin.
class ActualizarNivelCopagoPacienteUseCase {
  const ActualizarNivelCopagoPacienteUseCase(this._repository);

  final PerfilRepository _repository;

  Future<void> execute(String nivelCopagoId) {
    return _repository.actualizarNivelCopagoPaciente(nivelCopagoId);
  }
}
