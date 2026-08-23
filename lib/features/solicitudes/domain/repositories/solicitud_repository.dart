import '../entities/datos_solicitud.dart';
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
}
