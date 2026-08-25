import '../../../../shared/core/network/api_client.dart';
import '../../domain/value-objects/tipo_documento_domiciliario.dart';

/// Traduce las operaciones de perfil (HU-02) a requests concretos contra
/// `mediruta-api` — única capa que conoce las rutas/forma del JSON.
class PerfilRemoteDatasource {
  const PerfilRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> obtenerPerfil() async {
    final respuesta = await _apiClient.get('/perfil', autenticado: true);
    return respuesta as Map<String, dynamic>;
  }

  Future<void> actualizarDatosComunes({
    required String nombreCompleto,
    required String telefono,
  }) {
    return _apiClient.patch(
      '/perfil',
      body: {'nombreCompleto': nombreCompleto, 'telefono': telefono},
      autenticado: true,
    );
  }

  Future<void> actualizarPerfilPaciente({
    required String direccion,
    required String fechaNacimiento,
    required String departamento,
    required String ciudad,
  }) {
    return _apiClient.patch(
      '/perfil/paciente',
      body: {
        'direccion': direccion,
        'fechaNacimiento': fechaNacimiento,
        'departamento': departamento,
        'ciudad': ciudad,
      },
      autenticado: true,
    );
  }

  Future<void> subirFotoCedulaPaciente({
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) {
    return _apiClient.postMultipart(
      '/perfil/paciente/foto-cedula',
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      contentType: contentType,
      autenticado: true,
    );
  }

  Future<void> subirFotoPerfil({
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) {
    return _apiClient.postMultipart(
      '/perfil/foto',
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      contentType: contentType,
      autenticado: true,
    );
  }

  Future<void> actualizarPerfilDomiciliario({
    required String direccion,
    required String vehiculoTipo,
    required String vehiculoPlaca,
  }) {
    return _apiClient.patch(
      '/perfil/domiciliario',
      body: {
        'direccion': direccion,
        'vehiculoTipo': vehiculoTipo,
        'vehiculoPlaca': vehiculoPlaca,
      },
      autenticado: true,
    );
  }

  Future<void> subirDocumentoDomiciliario({
    required TipoDocumentoDomiciliario tipo,
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  }) {
    return _apiClient.postMultipart(
      '/perfil/domiciliario/documentos',
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      contentType: contentType,
      campos: {'tipo': tipo.valor},
      autenticado: true,
    );
  }

  Future<void> desactivarCuenta() {
    return _apiClient.post('/perfil/desactivar', autenticado: true);
  }

  Future<void> actualizarDisponibilidadDomiciliario({
    required bool disponible,
    double? lat,
    double? lng,
  }) {
    return _apiClient.post(
      '/perfil/domiciliario/disponibilidad',
      body: {'disponible': disponible, if (lat != null) 'lat': lat, if (lng != null) 'lng': lng},
      autenticado: true,
    );
  }
}
