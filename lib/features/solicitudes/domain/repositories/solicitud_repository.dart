import '../entities/datos_solicitud.dart';
import '../entities/documentos_paciente_para_recoger.dart';
import '../entities/pedido_activo.dart';
import '../entities/pedido_disponible.dart';
import '../entities/pedido_historial.dart';
import '../entities/solicitud.dart';
import '../entities/solicitud_resumen.dart';

/// Puerto del dominio de solicitudes (HU-03) — el dominio no sabe que
/// existe la API HTTP. Lo implementa `SolicitudRepositoryImpl` en `data/`.
abstract class SolicitudRepository {
  /// G01. La API bloquea (403) si el perfil del paciente no tiene foto
  /// de cédula cargada (HU-02) — se propaga como `ApiException`, mismo
  /// manejo que cualquier otro error de dominio.
  Future<String> crear(DatosSolicitud datos);

  /// G02.
  Future<List<SolicitudResumen>> listar();

  /// G03.
  Future<Solicitud> obtener(String solicitudId);

  /// G04 — solo si sigue en Borrador. Reemplaza todos los medicamentos
  /// por los recibidos.
  Future<void> actualizar(String solicitudId, DatosSolicitud datos);

  /// Sube/reemplaza la foto de la receta.
  Future<void> subirReceta({
    required String solicitudId,
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  });

  /// G05. Devuelve el código de pedido recién generado (`MR-000001`,
  /// ...) — no existía hasta este momento, un Borrador no es un pedido.
  Future<String> enviar(String solicitudId);

  /// G06.
  Future<void> cancelar(String solicitudId);

  /// HU-07 (ronda 2) — el Paciente también puede reportar una novedad
  /// sobre su propio pedido (antes solo el Domiciliario podía). No
  /// reutiliza [reportarNovedad] porque ese está scopeado al pedido
  /// activo del Domiciliario (`/pedidos/:id/novedad`); este pega a
  /// `/solicitudes/:id/novedad`.
  Future<void> reportarNovedadPaciente(String solicitudId, String detalle);

  // --- Domiciliario (HU-09/HU-07) ---

  /// Pool de pedidos disponibles, ya ordenado por distancia real a la
  /// farmacia. Vacío si no está disponible, no tiene ubicación todavía,
  /// o ya tiene un pedido activo.
  Future<List<PedidoDisponible>> listarPedidosDisponibles();

  /// Puede fallar con `409` (`ya lo aceptó otro` o `ya tenés un pedido
  /// activo`) — se propaga como `ApiException`, mismo manejo que
  /// cualquier otro error de dominio.
  Future<void> aceptarPedido(String solicitudId);

  Future<void> marcarMedicamentosRecogidos(String solicitudId);

  Future<void> iniciarEntrega(String solicitudId);

  Future<void> marcarEnSitio(String solicitudId);

  /// El código de 6 lo valida la API (case-insensitive); si no coincide
  /// responde `400`, propagado como `ApiException`.
  Future<void> entregarPedido(String solicitudId, String codigo);

  Future<void> reportarNovedad(String solicitudId, String detalle);

  /// El pedido que el Domiciliario tiene en curso ahora mismo, o `null`
  /// si no tiene ninguno — sobrevive un cierre/reapertura de la app (el
  /// pool deja de incluirlo apenas se acepta).
  Future<PedidoActivo?> obtenerPedidoActivo();

  /// "Mis pedidos" del Domiciliario — todos los que aceptó alguna vez.
  Future<List<PedidoHistorial>> listarHistorialPedidos();

  /// HU-07/HU-09 — cédula del Paciente (ambos lados), para mostrar en
  /// la farmacia al reclamar el medicamento. La API la niega (404)
  /// fuera de la ventana `asignado_en_camino_farmacia`.
  Future<DocumentosPacienteParaRecoger> obtenerDocumentosPacienteParaRecoger(
    String solicitudId,
  );
}
