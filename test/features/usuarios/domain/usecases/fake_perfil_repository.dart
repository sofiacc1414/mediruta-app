import 'package:mediruta_app/features/usuarios/domain/entities/perfil.dart';
import 'package:mediruta_app/features/usuarios/domain/entities/perfil_domiciliario.dart';
import 'package:mediruta_app/features/usuarios/domain/entities/perfil_paciente.dart';
import 'package:mediruta_app/features/usuarios/domain/repositories/perfil_repository.dart';
import 'package:mediruta_app/features/usuarios/domain/value-objects/tipo_documento_domiciliario.dart';

/// Fake escrito a mano del puerto `PerfilRepository` — mismo espíritu que
/// `fake_usuario_repository.dart` de HU-01 (sin mocktail/mockito).
class FakePerfilRepository implements PerfilRepository {
  Object? errorALanzar;
  Perfil perfilARetornar = const Perfil(
    nombreCompleto: null,
    telefono: null,
    fotoPerfilUrl: null,
    paciente: PerfilPaciente(
      direccion: null,
      fechaNacimiento: null,
      fotoCedulaUrl: null,
    ),
    domiciliario: PerfilDomiciliario(
      direccion: null,
      vehiculoTipo: null,
      vehiculoPlaca: null,
      cedulaUrl: null,
      licenciaUrl: null,
      soatUrl: null,
      tecnicomecanicaUrl: null,
    ),
  );

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
  Future<Perfil> obtenerPerfil() async {
    _registrar('obtenerPerfil', {});
    _lanzarSiCorresponde();
    return perfilARetornar;
  }

  @override
  Future<void> actualizarDatosComunes({
    required String nombreCompleto,
    required String telefono,
  }) async {
    _registrar('actualizarDatosComunes', {
      'nombreCompleto': nombreCompleto,
      'telefono': telefono,
    });
    _lanzarSiCorresponde();
  }

  @override
  Future<void> actualizarPerfilPaciente({
    required String direccion,
    required String fechaNacimiento,
  }) async {
    _registrar('actualizarPerfilPaciente', {
      'direccion': direccion,
      'fechaNacimiento': fechaNacimiento,
    });
    _lanzarSiCorresponde();
  }

  @override
  Future<void> subirFotoCedulaPaciente({
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) async {
    _registrar('subirFotoCedulaPaciente', {
      'bytes': bytes,
      'nombreArchivo': nombreArchivo,
      'contentType': contentType,
    });
    _lanzarSiCorresponde();
  }

  @override
  Future<void> subirFotoPerfil({
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) async {
    _registrar('subirFotoPerfil', {
      'bytes': bytes,
      'nombreArchivo': nombreArchivo,
      'contentType': contentType,
    });
    _lanzarSiCorresponde();
  }

  @override
  Future<void> actualizarPerfilDomiciliario({
    required String direccion,
    required String vehiculoTipo,
    required String vehiculoPlaca,
  }) async {
    _registrar('actualizarPerfilDomiciliario', {
      'direccion': direccion,
      'vehiculoTipo': vehiculoTipo,
      'vehiculoPlaca': vehiculoPlaca,
    });
    _lanzarSiCorresponde();
  }

  @override
  Future<void> subirDocumentoDomiciliario({
    required TipoDocumentoDomiciliario tipo,
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) async {
    _registrar('subirDocumentoDomiciliario', {
      'tipo': tipo,
      'bytes': bytes,
      'nombreArchivo': nombreArchivo,
      'contentType': contentType,
    });
    _lanzarSiCorresponde();
  }

  @override
  Future<void> desactivarCuenta() async {
    _registrar('desactivarCuenta', {});
    _lanzarSiCorresponde();
  }
}
