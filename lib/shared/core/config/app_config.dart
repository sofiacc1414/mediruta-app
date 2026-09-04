/// Configuración de entorno de la App. `apiBaseUrl` se resuelve en tiempo
/// de compilación vía `--dart-define=API_BASE_URL=...` (ver README) — sin
/// eso, apunta a la API de pruebas en Render, para que el equipo pueda
/// compilar y probar sin tener que acordarse del flag. Para developear
/// contra tu API local, pasa el flag apuntando a `http://localhost:3000`
/// (o `http://10.0.2.2:3000` en el emulador Android).
class AppConfig {
  AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mediruta-api-n9cg.onrender.com',
  );
}
