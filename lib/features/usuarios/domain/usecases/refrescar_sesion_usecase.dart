import '../repositories/usuario_repository.dart';

/// Uso interno (silent refresh): lo dispara `ApiClient.onSesionExpirada`
/// ante un 401 en un endpoint autenticado, y `AuthGate` al arrancar la app.
/// No es una pantalla — no corresponde a un Gxx directo, sostiene G03/G07.
class RefrescarSesionUseCase {
  const RefrescarSesionUseCase(this._repository);

  final UsuarioRepository _repository;

  Future<bool> execute() {
    return _repository.refrescarSesion();
  }
}
