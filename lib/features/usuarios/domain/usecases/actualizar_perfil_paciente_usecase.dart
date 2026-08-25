import '../repositories/perfil_repository.dart';

/// G01/G03 de HU-02 — dirección + fecha de nacimiento del Paciente.
/// `departamento`/`ciudad` son obligatorios desde HU-09.
class ActualizarPerfilPacienteUseCase {
  const ActualizarPerfilPacienteUseCase(this._repository);

  final PerfilRepository _repository;

  Future<void> execute({
    required String direccion,
    required String fechaNacimiento,
    required String departamento,
    required String ciudad,
  }) {
    return _repository.actualizarPerfilPaciente(
      direccion: direccion,
      fechaNacimiento: fechaNacimiento,
      departamento: departamento,
      ciudad: ciudad,
    );
  }
}
