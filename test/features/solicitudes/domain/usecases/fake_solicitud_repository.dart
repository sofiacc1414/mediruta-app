import 'package:mediruta_app/features/solicitudes/domain/entities/datos_solicitud.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/documentos_paciente_para_recoger.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/pedido_activo.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/pedido_disponible.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/pedido_historial.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/solicitud.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/solicitud_resumen.dart';
import 'package:mediruta_app/features/solicitudes/domain/repositories/solicitud_repository.dart';

/// Fake escrito a mano del puerto `SolicitudRepository` — mismo espíritu
/// que `fake_perfil_repository.dart` de HU-02 (sin mocktail/mockito).
class FakeSolicitudRepository implements SolicitudRepository {
  Object? errorALanzar;
  String idARetornar = 'solicitud-uuid';
  String codigoPedidoARetornar = 'MR-000123';
  List<SolicitudResumen> listaARetornar = const [];
  Solicitud? solicitudARetornar;
  List<PedidoDisponible> pedidosDisponiblesARetornar = const [];
  PedidoActivo? pedidoActivoARetornar;
  List<PedidoHistorial> historialPedidosARetornar = const [];
  DocumentosPacienteParaRecoger documentosPacienteParaRecogerARetornar =
      const DocumentosPacienteParaRecoger(cedulaFrenteUrl: null, cedulaReversoUrl: null);

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
  Future<void> subirReceta({
    required String solicitudId,
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) async {
    _registrar('subirReceta', {
      'solicitudId': solicitudId,
      'bytes': bytes,
      'nombreArchivo': nombreArchivo,
      'contentType': contentType,
    });
    _lanzarSiCorresponde();
  }

  @override
  Future<String> enviar(String solicitudId) async {
    _registrar('enviar', {'solicitudId': solicitudId});
    _lanzarSiCorresponde();
    return codigoPedidoARetornar;
  }

  @override
  Future<void> cancelar(String solicitudId) async {
    _registrar('cancelar', {'solicitudId': solicitudId});
    _lanzarSiCorresponde();
  }

  @override
  Future<List<PedidoDisponible>> listarPedidosDisponibles() async {
    _registrar('listarPedidosDisponibles', {});
    _lanzarSiCorresponde();
    return pedidosDisponiblesARetornar;
  }

  @override
  Future<void> aceptarPedido(String solicitudId) async {
    _registrar('aceptarPedido', {'solicitudId': solicitudId});
    _lanzarSiCorresponde();
  }

  @override
  Future<void> marcarMedicamentosRecogidos(String solicitudId) async {
    _registrar('marcarMedicamentosRecogidos', {'solicitudId': solicitudId});
    _lanzarSiCorresponde();
  }

  @override
  Future<void> iniciarEntrega(String solicitudId) async {
    _registrar('iniciarEntrega', {'solicitudId': solicitudId});
    _lanzarSiCorresponde();
  }

  @override
  Future<void> marcarEnSitio(String solicitudId) async {
    _registrar('marcarEnSitio', {'solicitudId': solicitudId});
    _lanzarSiCorresponde();
  }

  @override
  Future<void> entregarPedido(String solicitudId, String codigo) async {
    _registrar('entregarPedido', {'solicitudId': solicitudId, 'codigo': codigo});
    _lanzarSiCorresponde();
  }

  @override
  Future<void> reportarNovedad(String solicitudId, String detalle) async {
    _registrar('reportarNovedad', {'solicitudId': solicitudId, 'detalle': detalle});
    _lanzarSiCorresponde();
  }

  @override
  Future<PedidoActivo?> obtenerPedidoActivo() async {
    _registrar('obtenerPedidoActivo', {});
    _lanzarSiCorresponde();
    return pedidoActivoARetornar;
  }

  @override
  Future<List<PedidoHistorial>> listarHistorialPedidos() async {
    _registrar('listarHistorialPedidos', {});
    _lanzarSiCorresponde();
    return historialPedidosARetornar;
  }

  @override
  Future<DocumentosPacienteParaRecoger> obtenerDocumentosPacienteParaRecoger(
    String solicitudId,
  ) async {
    _registrar('obtenerDocumentosPacienteParaRecoger', {'solicitudId': solicitudId});
    _lanzarSiCorresponde();
    return documentosPacienteParaRecogerARetornar;
  }
}
