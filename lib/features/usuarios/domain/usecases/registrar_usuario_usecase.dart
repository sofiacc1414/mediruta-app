import '../repositories/usuario_repository.dart';

/// G01/G02 de HU-01 — registro público como Paciente o Domiciliario.
class RegistrarUsuarioUseCase {
  const RegistrarUsuarioUseCase(this._repository);

  final UsuarioRepository _repository;

  Future<void> execute({
    required String correo,
    required String password,
    required String tipoRegistro,
    bool? altaPaciente,
  }) {
    return _repository.registrar(
      correo: correo,
      password: password,
      tipoRegistro: tipoRegistro,
      altaPaciente: altaPaciente,
    );
  }
}
