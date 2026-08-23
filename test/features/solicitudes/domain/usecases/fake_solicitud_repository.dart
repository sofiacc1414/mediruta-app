import 'package:mediruta_app/features/solicitudes/domain/entities/datos_solicitud.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/solicitud.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/solicitud_resumen.dart';
import 'package:mediruta_app/features/solicitudes/domain/repositories/solicitud_repository.dart';

/// Fake escrito a mano del puerto `SolicitudRepository` — mismo espíritu
/// que `fake_perfil_repository.dart` de HU-02 (sin mocktail/mockito).
class FakeSolicitudRepository implements SolicitudRepository {
  Object? errorALanzar;
  String idARetornar = 'solicitud-uuid';
  List<SolicitudResumen> listaARetornar = const [];
  Solicitud? solicitudARetornar;

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
  Future<String> crear(DatosSolicitud datos) async {
    _registrar('crear', {'datos': datos});
    _lanzarSiCorresponde();
    return idARetornar;
  }

  @override
  Future<List<SolicitudResumen>> listar() async {
    _registrar('listar', {});
    _lanzarSiCorresponde();
    return listaARetornar;
  }

  @override
  Future<Solicitud> obtener(String solicitudId) async {
    _registrar('obtener', {'solicitudId': solicitudId});
    _lanzarSiCorresponde();
    return solicitudARetornar!;
  }

  @override
  Future<void> actualizar(String solicitudId, DatosSolicitud datos) async {
    _registrar('actualizar', {'solicitudId': solicitudId, 'datos': datos});
    _lanzarSiCorresponde();
  }

  @override
  Future<void> enviar(String solicitudId) async {
    _registrar('enviar', {'solicitudId': solicitudId});
    _lanzarSiCorresponde();
  }

  @override
  Future<void> cancelar(String solicitudId) async {
    _registrar('cancelar', {'solicitudId': solicitudId});
    _lanzarSiCorresponde();
  }
}
