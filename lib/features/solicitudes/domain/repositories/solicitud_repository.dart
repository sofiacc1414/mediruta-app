import '../entities/datos_solicitud.dart';
import '../entities/solicitud.dart';
import '../entities/solicitud_resumen.dart';

/// Puerto del dominio de solicitudes (HU-03) — el dominio no sabe que
/// existe la API HTTP. Lo implementa `SolicitudRepositoryImpl` en `data/`.
abstract class SolicitudRepository {
  /// G01.
  Future<String> crear(DatosSolicitud datos);

  /// G02.
  Future<List<SolicitudResumen>> listar();

  /// G03.
  Future<Solicitud> obtener(String solicitudId);

  /// G04 — solo si sigue en Borrador.
  Future<void> actualizar(String solicitudId, DatosSolicitud datos);

  /// G05.
  Future<void> enviar(String solicitudId);

  /// G06.
  Future<void> cancelar(String solicitudId);
}
