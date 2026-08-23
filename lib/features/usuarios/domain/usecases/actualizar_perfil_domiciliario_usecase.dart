import '../repositories/perfil_repository.dart';

/// G01/G03 de HU-02 — dirección + vehículo del Domiciliario.
class ActualizarPerfilDomiciliarioUseCase {
  const ActualizarPerfilDomiciliarioUseCase(this._repository);

  final PerfilRepository _repository;

  Future<void> execute({
    required String direccion,
    required String vehiculoTipo,
    required String vehiculoPlaca,
  }) {
    return _repository.actualizarPerfilDomiciliario(
      direccion: direccion,
      vehiculoTipo: vehiculoTipo,
      vehiculoPlaca: vehiculoPlaca,
    );
  }
}
