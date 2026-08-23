import '../repositories/perfil_repository.dart';

/// G05 de HU-02 — desactiva la cuenta en la API. La limpieza de la
/// sesión local y la navegación a login las orquesta la pantalla,
/// reutilizando `authSessionProvider.cerrarSesion()` (mismo mecanismo
/// de HU-01, sin duplicar el manejo de tokens acá).
class DesactivarCuentaUseCase {
  const DesactivarCuentaUseCase(this._repository);

  final PerfilRepository _repository;

  Future<void> execute() {
    return _repository.desactivarCuenta();
  }
}
