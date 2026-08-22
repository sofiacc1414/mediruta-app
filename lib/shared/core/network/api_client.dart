import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper base para hablar con la API de MediRuta.
///
/// La App NUNCA llama a Supabase directamente — ni para datos ni para
/// autenticación (DOCS/context.md, Parte B, secciones 4.1 y 11). Todo pasa
/// por aquí. El token JWT (propio, emitido por la API) se guarda en
/// almacenamiento seguro, nunca en SharedPreferences ni en memoria plana.
class ApiClient {
  ApiClient({required this.baseUrl, FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final String baseUrl;
  final FlutterSecureStorage _secureStorage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<String?> get accessToken => _secureStorage.read(key: _accessTokenKey);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  // Los métodos get/post/patch/delete concretos (con manejo de headers,
  // refresh automático de token, y parsing de errores) se implementan
  // junto con el primer caso de uso que los necesite (HU-01), no antes
  // — ver "planificación obligatoria antes de implementar", sección 12.
}
