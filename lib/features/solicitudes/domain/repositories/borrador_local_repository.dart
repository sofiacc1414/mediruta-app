import '../entities/datos_solicitud.dart';

/// Puerto de la persistencia LOCAL del borrador en progreso de "Nueva
/// solicitud" — nunca habla con la API. Mientras el paciente completa el
/// formulario, nada viaja a la BD; recién se llama a
/// `SolicitudRepository.crear` cuando confirma (completó todo, o eligió
/// "guardar para continuar después" al intentar salir).
abstract class BorradorLocalRepository {
  Future<void> guardar(DatosSolicitud datos);
  Future<DatosSolicitud?> leer();
  Future<void> limpiar();
}
