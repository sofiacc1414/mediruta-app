/// Error de un request a la API. Expone el `message` que manda
/// `DominioHttpFilter` (errores de dominio) o el `ValidationPipe` global
/// (errores de validación, con `exceptionFactory` propio para que salgan
/// en español — ver `mensajes-validacion.ts` del lado de la API) — nunca
/// se inventa un texto distinto acá, se muestra el mismo mensaje que la
/// API decidió mandar (DOCS/context.md, Parte B, sección 4.1 y 4.2 —
/// mensajes genéricos anti-enumeración en login/recuperación).
class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  /// true si la API respondió 401 (sesión inválida/expirada).
  bool get esNoAutorizado => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// El dispositivo no pudo alcanzar la API (sin conexión, DNS, timeout, etc.)
/// — distinto de un ApiException, que sí implica que la API respondió.
class ApiSinConexionException implements Exception {
  const ApiSinConexionException();

  @override
  String toString() =>
      'No se pudo conectar con el servidor. Revisa tu conexión e intenta de nuevo.';
}
