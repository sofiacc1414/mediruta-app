import '../repositories/solicitud_repository.dart';

/// Sube/reemplaza la foto de la receta médica de una solicitud.
class SubirRecetaUseCase {
  const SubirRecetaUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<void> execute({
    required String solicitudId,
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) {
    return _repository.subirReceta(
      solicitudId: solicitudId,
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      contentType: contentType,
    );
  }
}
