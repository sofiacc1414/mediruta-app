import '../repositories/usuario_repository.dart';

/// Agrega el rol DOMICILIARIO (pendiente_validacion) a la cuenta
/// autenticada — de ahí en más sigue el mismo flujo de completar
/// perfil/documentos (HU-02) y aprobación del admin (HU-08) que ya
/// existe. Idempotente — pedirlo de nuevo no es un error.
class SolicitarRolDomiciliarioUseCase {
  const SolicitarRolDomiciliarioUseCase(this._repository);

  final UsuarioRepository _repository;

  Future<String> execute() {
    return _repository.solicitarRolDomiciliario();
  }
}
