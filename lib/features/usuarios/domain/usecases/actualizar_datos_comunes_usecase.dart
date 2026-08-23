import '../repositories/perfil_repository.dart';

/// G03/G04 de HU-02 — nombre y teléfono, comunes a cualquier rol.
class ActualizarDatosComunesUseCase {
  const ActualizarDatosComunesUseCase(this._repository);

  final PerfilRepository _repository;

  Future<void> execute({
    required String nombreCompleto,
    required String telefono,
  }) {
    return _repository.actualizarDatosComunes(
      nombreCompleto: nombreCompleto,
      telefono: telefono,
    );
  }
}
