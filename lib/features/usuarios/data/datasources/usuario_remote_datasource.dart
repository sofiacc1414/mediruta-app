import '../../../../shared/core/network/api_client.dart';

/// Traduce las operaciones de `usuarios` a requests concretos contra
/// `mediruta-api`. Es la única capa que conoce las rutas/forma del JSON de
/// la API — el resto del feature (repository, usecases, presentation) no
/// sabe nada de HTTP (DOCS/context.md, Parte B, sección 11).
class UsuarioRemoteDatasource {
  const UsuarioRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<void> registrar({
    required String correo,
    required String password,
    required String tipoRegistro,
    bool? altaPaciente,
  }) {
    return _apiClient.post(
      '/auth/registro',
      body: {
        'correo': correo,
        'password': password,
        'tipoRegistro': tipoRegistro,
        if (altaPaciente != null) 'altaPaciente': altaPaciente,
      },
    );
  }

  Future<Map<String, dynamic>> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    final respuesta = await _apiClient.post(
      '/auth/login',
      body: {'correo': correo, 'password': password},
    );
    return respuesta as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> obtenerSesionActual() async {
    final respuesta = await _apiClient.get('/auth/me', autenticado: true);
    return respuesta as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refrescarSesion({
    required String refreshToken,
  }) async {
    final respuesta = await _apiClient.post(
      '/auth/refrescar',
      body: {'refreshToken': refreshToken},
    );
    return respuesta as Map<String, dynamic>;
  }

  Future<void> cerrarSesion() {
    return _apiClient.post('/auth/logout', autenticado: true);
  }

  Future<void> solicitarRecuperacionContrasena({required String correo}) {
    return _apiClient.post(
      '/auth/recuperar-contrasena',
      body: {'correo': correo},
    );
  }

  Future<void> restablecerContrasena({
    required String correo,
    required String codigo,
    required String nuevaPassword,
  }) {
    return _apiClient.post(
      '/auth/restablecer-contrasena',
      body: {'correo': correo, 'codigo': codigo, 'nuevaPassword': nuevaPassword},
    );
  }

  Future<void> cambiarContrasena({
    required String passwordActual,
    required String nuevaPassword,
  }) {
    return _apiClient.post(
      '/auth/cambiar-contrasena',
      body: {
        'passwordActual': passwordActual,
        'nuevaPassword': nuevaPassword,
      },
      autenticado: true,
    );
  }

  Future<Map<String, dynamic>> solicitarRolPaciente() async {
    final respuesta = await _apiClient.post(
      '/perfil/paciente/solicitar',
      autenticado: true,
    );
    return respuesta as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> solicitarRolDomiciliario() async {
    final respuesta = await _apiClient.post(
      '/perfil/domiciliario/solicitar',
      autenticado: true,
    );
    return respuesta as Map<String, dynamic>;
  }
}
