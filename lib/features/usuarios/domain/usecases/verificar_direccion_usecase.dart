import '../entities/verificacion_direccion.dart';
import '../repositories/perfil_repository.dart';

/// Ronda 12 — geocodifica sin guardar (loader + candidatos apenas se
/// pierde el foco del campo de dirección del perfil).
class VerificarDireccionUseCase {
  const VerificarDireccionUseCase(this._repository);

  final PerfilRepository _repository;

  Future<VerificacionDireccion> execute({
    required String direccion,
    String? departamento,
    String? ciudad,
  }) {
    return _repository.verificarDireccion(
      direccion: direccion,
      departamento: departamento,
      ciudad: ciudad,
    );
  }
}
