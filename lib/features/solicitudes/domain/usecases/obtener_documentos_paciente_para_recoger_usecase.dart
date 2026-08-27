import '../entities/documentos_paciente_para_recoger.dart';
import '../repositories/solicitud_repository.dart';

/// HU-07/HU-09 — cédula del Paciente (ambos lados), para que el
/// Domiciliario la muestre en la farmacia al reclamar el medicamento a
/// su nombre. La API la niega (404) fuera de la ventana
/// `asignado_en_camino_farmacia` — por seguridad/privacidad no hay
/// motivo legítimo para verla en ningún otro momento.
class ObtenerDocumentosPacienteParaRecogerUseCase {
  const ObtenerDocumentosPacienteParaRecogerUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<DocumentosPacienteParaRecoger> execute(String solicitudId) {
    return _repository.obtenerDocumentosPacienteParaRecoger(solicitudId);
  }
}
