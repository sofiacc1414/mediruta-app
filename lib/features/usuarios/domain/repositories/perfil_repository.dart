import '../entities/perfil.dart';
import '../value-objects/tipo_documento_domiciliario.dart';

/// Puerto del dominio de perfil (HU-02) — el dominio no sabe que existe
/// la API HTTP. Lo implementa `PerfilRepositoryImpl` en `data/`.
abstract class PerfilRepository {
  /// G02.
  Future<Perfil> obtenerPerfil();

  /// G03/G04 — nombre y teléfono, comunes a cualquier rol.
  Future<void> actualizarDatosComunes({
    required String nombreCompleto,
    required String telefono,
  });

  /// G01/G03 — dirección + fecha de nacimiento del Paciente.
  Future<void> actualizarPerfilPaciente({
    required String direccion,
    required String fechaNacimiento,
  });

  /// G01/G03 — foto de cédula del Paciente.
  Future<void> subirFotoCedulaPaciente({
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  });

  /// Foto de perfil (avatar), común a cualquier rol.
  Future<void> subirFotoPerfil({
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  });

  /// G01/G03 — dirección + vehículo del Domiciliario.
  Future<void> actualizarPerfilDomiciliario({
    required String direccion,
    required String vehiculoTipo,
    required String vehiculoPlaca,
  });

  /// G01/G03 — documento del Domiciliario (cédula/licencia/SOAT/tecnomecánica).
  Future<void> subirDocumentoDomiciliario({
    required TipoDocumentoDomiciliario tipo,
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
  });

  /// G05 — desactiva la cuenta y cierra la sesión.
  Future<void> desactivarCuenta();
}
