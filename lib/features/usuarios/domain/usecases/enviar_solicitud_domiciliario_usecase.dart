import '../repositories/usuario_repository.dart';

/// Envía la solicitud de validación de Domiciliario: `borrador` ->
/// `pendiente_validacion`. Recién ahí la ve el admin (HU-08) — completar
/// el perfil/documentos (HU-02) no la envía sola, hace falta esta acción
/// explícita, mismo criterio que `EnviarSolicitudUseCase` de HU-03.
class EnviarSolicitudDomiciliarioUseCase {
  const EnviarSolicitudDomiciliarioUseCase(this._repository);

  final UsuarioRepository _repository;

  Future<String> execute() {
    return _repository.enviarSolicitudDomiciliario();
  }
}
