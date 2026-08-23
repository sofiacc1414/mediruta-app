import '../entities/usuario.dart';

/// Puerto del dominio de `usuarios` — el dominio no sabe que existe la API
/// HTTP ni Supabase, solo conoce este contrato (DOCS/context.md, Parte B,
/// sección 11). Lo implementa `UsuarioRepositoryImpl` en `data/`.
abstract class UsuarioRepository {
  /// G01/G02 — registro público. Solo PACIENTE o DOMICILIARIO.
  /// `altaPaciente` solo tiene efecto si `tipoRegistro == DOMICILIARIO`
  /// — no todos los domiciliarios quieren ser también pacientes.
  Future<void> registrar({
    required String correo,
    required String password,
    required String tipoRegistro,
    bool? altaPaciente,
  });

  /// G03/G04 — login. Persiste los tokens y devuelve la identidad.
  Future<Usuario> iniciarSesion({
    required String correo,
    required String password,
  });

  /// GET /auth/me — sesión actual a partir del access token guardado.
  Future<Usuario> obtenerSesionActual();

  /// Renueva el access token usando el refresh token guardado. Devuelve
  /// `true` si lo logró (y ya persistió el nuevo par de tokens).
  Future<bool> refrescarSesion();

  /// G07 — revoca la sesión actual en la API y limpia los tokens locales.
  Future<void> cerrarSesion();

  /// G05 paso 1 — solicita el OTP de recuperación por correo.
  Future<void> solicitarRecuperacionContrasena({required String correo});

  /// G05 paso 2 — consume el OTP y fija una nueva contraseña.
  Future<void> restablecerContrasena({
    required String correo,
    required String codigo,
    required String nuevaPassword,
  });

  /// G06 — cambio de contraseña con sesión activa.
  Future<void> cambiarContrasena({
    required String passwordActual,
    required String nuevaPassword,
  });

  /// true si hay tokens guardados localmente (no implica que sigan siendo
  /// válidos en la API — eso lo confirma `obtenerSesionActual`).
  Future<bool> haySesionGuardada();

  /// Agrega el rol PACIENTE a la cuenta autenticada, si todavía no lo
  /// tiene (idempotente). Devuelve el mensaje de la API.
  Future<String> solicitarRolPaciente();

  /// Agrega el rol DOMICILIARIO (pendiente_validacion) a la cuenta
  /// autenticada, si todavía no lo tiene (idempotente). Devuelve el
  /// mensaje de la API.
  Future<String> solicitarRolDomiciliario();
}
