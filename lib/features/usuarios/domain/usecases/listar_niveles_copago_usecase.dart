import '../entities/nivel_copago.dart';
import '../repositories/perfil_repository.dart';

/// Catálogo de niveles de copago — lo necesita el Paciente para elegir
/// el suyo en su perfil.
class ListarNivelesCopagoUseCase {
  const ListarNivelesCopagoUseCase(this._repository);

  final PerfilRepository _repository;

  Future<List<NivelCopago>> execute() {
    return _repository.listarNivelesCopago();
  }
}
