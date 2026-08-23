import '../../../../shared/core/network/api_client.dart';
import '../../../../shared/core/network/api_exception.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/usuario_repository.dart';
import '../datasources/usuario_remote_datasource.dart';

/// Implementa el puerto `UsuarioRepository`. Es la única capa que conoce
/// tanto el datasource (HTTP) como el manejo de tokens del `ApiClient` — el
/// dominio (usecases) nunca toca tokens directamente.
class UsuarioRepositoryImpl implements UsuarioRepository {
  const UsuarioRepositoryImpl(this._datasource, this._apiClient);

  final UsuarioRemoteDatasource _datasource;
  final ApiClient _apiClient;

  @override
  Future<void> registrar({
    required String correo,
    required String password,
    required String tipoRegistro,
  }) {
    return _datasource.registrar(
      correo: correo,
      password: password,
      tipoRegistro: tipoRegistro,
    );
  }

  @override
  Future<Usuario> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    final respuesta = await _datasource.iniciarSesion(
      correo: correo,
      password: password,
    );

    await _apiClient.saveTokens(
      accessToken: respuesta['accessToken'] as String,
      refreshToken: respuesta['refreshToken'] as String,
    );

    return Usuario.fromJson(respuesta['usuario'] as Map<String, dynamic>);
  }

  @override
  Future<Usuario> obtenerSesionActual() async {
    final respuesta = await _datasource.obtenerSesionActual();
    return Usuario.fromJson(respuesta['usuario'] as Map<String, dynamic>);
  }

  @override
  Future<bool> refrescarSesion() async {
    final refreshTokenGuardado = await _apiClient.refreshToken;
    if (refreshTokenGuardado == null) {
      return false;
    }

    try {
      final respuesta = await _datasource.refrescarSesion(
        refreshToken: refreshTokenGuardado,
      );
      await _apiClient.saveTokens(
        accessToken: respuesta['accessToken'] as String,
        refreshToken: respuesta['refreshToken'] as String,
      );
      return true;
    } on ApiException catch (error) {
      if (error.esNoAutorizado) {
        // El refresh token ya no sirve (revocado/expirado/consumido) — no
        // hay sesión que restaurar, se limpia para forzar login.
        await _apiClient.clearTokens();
      }
      return false;
    } on ApiSinConexionException {
      // Falla temporal de red: se conservan los tokens para reintentar
      // más adelante, no se fuerza logout.
      return false;
    }
  }

  @override
  Future<void> cerrarSesion() async {
    try {
      await _datasource.cerrarSesion();
    } finally {
      await _apiClient.clearTokens();
    }
  }

  @override
  Future<void> solicitarRecuperacionContrasena({required String correo}) {
    return _datasource.solicitarRecuperacionContrasena(correo: correo);
  }

  @override
  Future<void> restablecerContrasena({
    required String correo,
    required String codigo,
    required String nuevaPassword,
  }) {
    return _datasource.restablecerContrasena(
      correo: correo,
      codigo: codigo,
      nuevaPassword: nuevaPassword,
    );
  }

  @override
  Future<void> cambiarContrasena({
    required String passwordActual,
    required String nuevaPassword,
  }) {
    return _datasource.cambiarContrasena(
      passwordActual: passwordActual,
      nuevaPassword: nuevaPassword,
    );
  }

  @override
  Future<bool> haySesionGuardada() async {
    return await _apiClient.accessToken != null;
  }
}
