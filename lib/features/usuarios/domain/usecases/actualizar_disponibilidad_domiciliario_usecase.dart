import '../repositories/perfil_repository.dart';

/// HU-09 — el Domiciliario prende/apaga "Disponible para recibir
/// pedidos". La ubicación (la manda el celular) es obligatoria al
/// activar, no al desactivar.
class ActualizarDisponibilidadDomiciliarioUseCase {
  const ActualizarDisponibilidadDomiciliarioUseCase(this._repository);

  final PerfilRepository _repository;

  Future<void> execute({required bool disponible, double? lat, double? lng}) {
    return _repository.actualizarDisponibilidadDomiciliario(
      disponible: disponible,
      lat: lat,
      lng: lng,
    );
  }
}
