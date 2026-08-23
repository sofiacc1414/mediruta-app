import '../repositories/usuario_repository.dart';

/// Chequeo rápido (sin red) de si hay tokens locales antes de intentar
/// restaurar sesión al arrancar la app — evita un round-trip innecesario
/// a `GET /auth/me` cuando ni siquiera hay un token guardado.
class HaySesionGuardadaUseCase {
  const HaySesionGuardadaUseCase(this._repository);

  final UsuarioRepository _repository;

  Future<bool> execute() {
    return _repository.haySesionGuardada();
  }
}
