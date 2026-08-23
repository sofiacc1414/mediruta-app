import 'package:mediruta_app/features/usuarios/domain/entities/usuario.dart';
import 'package:mediruta_app/features/usuarios/domain/repositories/usuario_repository.dart';

/// Fake escrito a mano del puerto `UsuarioRepository` — sin mocktail/mockito
/// (ninguno está declarado en el proyecto). Cada método registra cómo fue
/// llamado y devuelve/lanza lo que el test configure, mismo espíritu que
/// los fakes usados en `mediruta-api` (ej. `iniciar-sesion.use-case.spec.ts`).
class FakeUsuarioRepository implements UsuarioRepository {
  Object? errorALanzar;

  Usuario? usuarioARetornar;
  bool refrescarSesionResultado = true;
  bool haySesionGuardadaResultado = true;
  String solicitarRolPacienteResultado = 'Ahora también sos Paciente.';
  String solicitarRolDomiciliarioResultado =
      'Listo — completá tus datos de Domiciliario para que un administrador te valide.';
  String enviarSolicitudDomiciliarioResultado = 'Tu solicitud fue enviada para validación.';

  Map<String, dynamic>? ultimaLlamada;

  void _registrar(String metodo, Map<String, dynamic> args) {
    ultimaLlamada = {'metodo': metodo, ...args};
  }

  void _lanzarSiCorresponde() {
    if (errorALanzar != null) {
      // ignore: only_throw_errors
      throw errorALanzar!;
    }
  }

  @override
  Future<void> registrar({
    required String correo,
    required String password,
    required String tipoRegistro,
    bool? altaPaciente,
  }) async {
    _registrar('registrar', {
      'correo': correo,
      'password': password,
      'tipoRegistro': tipoRegistro,
      'altaPaciente': altaPaciente,
    });
    _lanzarSiCorresponde();
  }

  @override
  Future<Usuario> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    _registrar('iniciarSesion', {'correo': correo, 'password': password});
    _lanzarSiCorresponde();
    return usuarioARetornar!;
  }

  @override
  Future<Usuario> obtenerSesionActual() async {
    _registrar('obtenerSesionActual', {});
    _lanzarSiCorresponde();
    return usuarioARetornar!;
  }

  @override
  Future<bool> refrescarSesion() async {
    _registrar('refrescarSesion', {});
    _lanzarSiCorresponde();
    return refrescarSesionResultado;
  }

  @override
  Future<void> cerrarSesion() async {
    _registrar('cerrarSesion', {});
    _lanzarSiCorresponde();
  }

  @override
  Future<void> solicitarRecuperacionContrasena({required String correo}) async {
    _registrar('solicitarRecuperacionContrasena', {'correo': correo});
    _lanzarSiCorresponde();
  }

  @override
  Future<void> restablecerContrasena({
    required String correo,
    required String codigo,
    required String nuevaPassword,
  }) async {
    _registrar('restablecerContrasena', {
      'correo': correo,
      'codigo': codigo,
      'nuevaPassword': nuevaPassword,
    });
    _lanzarSiCorresponde();
  }

  @override
  Future<void> cambiarContrasena({
    required String passwordActual,
    required String nuevaPassword,
  }) async {
    _registrar('cambiarContrasena', {
      'passwordActual': passwordActual,
      'nuevaPassword': nuevaPassword,
    });
    _lanzarSiCorresponde();
  }

  @override
  Future<bool> haySesionGuardada() async {
    _registrar('haySesionGuardada', {});
    return haySesionGuardadaResultado;
  }

  @override
  Future<String> solicitarRolPaciente() async {
    _registrar('solicitarRolPaciente', {});
    _lanzarSiCorresponde();
    return solicitarRolPacienteResultado;
  }

  @override
  Future<String> solicitarRolDomiciliario() async {
    _registrar('solicitarRolDomiciliario', {});
    _lanzarSiCorresponde();
    return solicitarRolDomiciliarioResultado;
  }

  @override
  Future<String> enviarSolicitudDomiciliario() async {
    _registrar('enviarSolicitudDomiciliario', {});
    _lanzarSiCorresponde();
    return enviarSolicitudDomiciliarioResultado;
  }
}
