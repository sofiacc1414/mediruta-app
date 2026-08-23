import '../repositories/perfil_repository.dart';

/// G01/G03 de HU-02 — dirección + fecha de nacimiento del Paciente.
class ActualizarPerfilPacienteUseCase {
  const ActualizarPerfilPacienteUseCase(this._repository);

  final PerfilRepository _repository;

  Future<void> execute({
    required String direccion,
    required String fechaNacimiento,
  }) {
    return _repository.actualizarPerfilPaciente(
      direccion: direccion,
      fechaNacimiento: fechaNacimiento,
    );
  }
}
