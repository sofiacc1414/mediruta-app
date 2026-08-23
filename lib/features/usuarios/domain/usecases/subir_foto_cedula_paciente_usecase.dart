import '../repositories/perfil_repository.dart';

/// G01/G03 de HU-02 — foto de cédula del Paciente.
class SubirFotoCedulaPacienteUseCase {
  const SubirFotoCedulaPacienteUseCase(this._repository);

  final PerfilRepository _repository;

  Future<void> execute({
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) {
    return _repository.subirFotoCedulaPaciente(
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      contentType: contentType,
    );
  }
}
