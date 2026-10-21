import '../entities/formula_extraida.dart';
import '../repositories/solicitud_repository.dart';

/// Módulo 1 (OCR) — lee una foto/PDF de fórmula médica para precargar
/// medicamentos y fecha en `NuevaSolicitudScreen`.
class ExtraerDatosFormulaUseCase {
  const ExtraerDatosFormulaUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<FormulaExtraida> execute({
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) {
    return _repository.extraerDatosFormula(
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      contentType: contentType,
    );
  }
}
