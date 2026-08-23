/// Configuración de entorno de la App. `apiBaseUrl` se resuelve en tiempo
/// de compilación vía `--dart-define=API_BASE_URL=...` (ver README) — sin
/// eso, apunta al servidor local por defecto para desarrollo.
class AppConfig {
  AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
