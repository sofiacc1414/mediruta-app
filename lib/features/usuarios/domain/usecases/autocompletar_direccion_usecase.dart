import '../entities/verificacion_direccion.dart';
import '../repositories/perfil_repository.dart';

/// Ronda 13 — sugerencias mientras se escribe, no solo al perder el
/// foco. Ver `VerificarDireccionUseCase` para la confirmación final.
class AutocompletarDireccionUseCase {
  const AutocompletarDireccionUseCase(this._repository);

  final PerfilRepository _repository;

  Future<List<CandidatoDireccionPerfil>> execute({
    required String texto,
    String? departamento,
    String? ciudad,
  }) {
    return _repository.autocompletarDireccion(
      texto: texto,
      departamento: departamento,
      ciudad: ciudad,
    );
  }
}
