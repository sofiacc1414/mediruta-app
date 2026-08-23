import '../repositories/perfil_repository.dart';

/// Foto de perfil (avatar), común a cualquier rol. No corresponde a un Gxx
/// específico de HU-02 (se agregó a pedido explícito, mismo patrón de
/// Storage ya construido para esa historia).
class SubirFotoPerfilUseCase {
  const SubirFotoPerfilUseCase(this._repository);

  final PerfilRepository _repository;

  Future<void> execute({
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) {
    return _repository.subirFotoPerfil(
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      contentType: contentType,
    );
  }
}
