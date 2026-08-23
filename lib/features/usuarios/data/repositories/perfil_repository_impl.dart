import '../../domain/entities/perfil.dart';
import '../../domain/repositories/perfil_repository.dart';
import '../../domain/value-objects/tipo_documento_domiciliario.dart';
import '../datasources/perfil_remote_datasource.dart';

class PerfilRepositoryImpl implements PerfilRepository {
  const PerfilRepositoryImpl(this._datasource);

  final PerfilRemoteDatasource _datasource;

  @override
  Future<Perfil> obtenerPerfil() async {
    final respuesta = await _datasource.obtenerPerfil();
    return Perfil.fromJson(respuesta);
  }

  @override
  Future<void> actualizarDatosComunes({
    required String nombreCompleto,
    required String telefono,
  }) {
    return _datasource.actualizarDatosComunes(
      nombreCompleto: nombreCompleto,
      telefono: telefono,
    );
  }

  @override
  Future<void> actualizarPerfilPaciente({
    required String direccion,
    required String fechaNacimiento,
  }) {
    return _datasource.actualizarPerfilPaciente(
      direccion: direccion,
      fechaNacimiento: fechaNacimiento,
    );
  }

  @override
  Future<void> subirFotoCedulaPaciente({
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) {
    return _datasource.subirFotoCedulaPaciente(
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      contentType: contentType,
    );
  }

  @override
  Future<void> actualizarPerfilDomiciliario({
    required String direccion,
    required String vehiculoTipo,
    required String vehiculoPlaca,
  }) {
    return _datasource.actualizarPerfilDomiciliario(
      direccion: direccion,
      vehiculoTipo: vehiculoTipo,
      vehiculoPlaca: vehiculoPlaca,
    );
  }

  @override
  Future<void> subirDocumentoDomiciliario({
    required TipoDocumentoDomiciliario tipo,
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) {
    return _datasource.subirDocumentoDomiciliario(
      tipo: tipo,
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      contentType: contentType,
    );
  }

  @override
  Future<void> desactivarCuenta() {
    return _datasource.desactivarCuenta();
  }
}
