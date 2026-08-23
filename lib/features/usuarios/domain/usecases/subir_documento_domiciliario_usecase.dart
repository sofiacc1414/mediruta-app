import '../repositories/perfil_repository.dart';
import '../value-objects/tipo_documento_domiciliario.dart';

/// G01/G03 de HU-02 — documento del Domiciliario (cédula/licencia/SOAT/
/// tecnomecánica).
class SubirDocumentoDomiciliarioUseCase {
  const SubirDocumentoDomiciliarioUseCase(this._repository);

  final PerfilRepository _repository;

  Future<void> execute({
    required TipoDocumentoDomiciliario tipo,
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) {
    return _repository.subirDocumentoDomiciliario(
      tipo: tipo,
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      contentType: contentType,
    );
  }
}
