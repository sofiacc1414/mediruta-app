import '../repositories/perfil_repository.dart';
import '../value-objects/lado_documento.dart';

/// G01/G03 de HU-02 — foto de un lado (frente o reverso) de la cédula
/// del Paciente. Se sube uno a la vez.
class SubirFotoCedulaPacienteUseCase {
  const SubirFotoCedulaPacienteUseCase(this._repository);

  final PerfilRepository _repository;

  Future<void> execute({
    required LadoDocumento lado,
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) {
    return _repository.subirFotoCedulaPaciente(
      lado: lado,
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      contentType: contentType,
    );
  }
}
