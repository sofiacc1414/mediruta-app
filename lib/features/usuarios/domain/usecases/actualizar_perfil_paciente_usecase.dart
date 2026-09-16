import '../repositories/perfil_repository.dart';

/// G01/G03 de HU-02 — dirección + fecha de nacimiento del Paciente.
/// `departamento`/`ciudad` son obligatorios desde HU-09.
class ActualizarPerfilPacienteUseCase {
  const ActualizarPerfilPacienteUseCase(this._repository);

  final PerfilRepository _repository;

  /// Ronda 14 — `direccionVerificada` en `true` solo cuando esta
  /// dirección exacta ya se confirmó contra Nominatim en esta misma
  /// sesión (chequeo en vivo, o al elegir una sugerencia) y no se
  /// volvió a editar después — evita que el guardado repita la
  /// geocodificación y se tope con una falla que la primera consulta
  /// ya no tuvo (ver doc del lado de la API).
  Future<void> execute({
    required String direccion,
    required String fechaNacimiento,
    required String departamento,
    required String ciudad,
    required bool direccionVerificada,
  }) {
    return _repository.actualizarPerfilPaciente(
      direccion: direccion,
      fechaNacimiento: fechaNacimiento,
      departamento: departamento,
      ciudad: ciudad,
      direccionVerificada: direccionVerificada,
    );
  }
}
