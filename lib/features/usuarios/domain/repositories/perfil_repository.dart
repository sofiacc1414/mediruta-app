import '../entities/perfil.dart';
import '../value-objects/lado_documento.dart';
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
  /// `departamento`/`ciudad` son obligatorios desde HU-09 (contexto de
  /// geocodificación de sus pedidos).
  Future<void> actualizarPerfilPaciente({
    required String direccion,
    required String fechaNacimiento,
    required String departamento,
    required String ciudad,
  });

  /// G01/G03 — foto de un lado (frente o reverso) de la cédula del
  /// Paciente. Los dos lados se suben por separado.
  Future<void> subirFotoCedulaPaciente({
    required LadoDocumento lado,
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

  /// HU-09 — prende/apaga "Disponible para recibir pedidos". `lat`/`lng`
  /// (la manda el celular) son obligatorios solo al activar.
  Future<void> actualizarDisponibilidadDomiciliario({
    required bool disponible,
    double? lat,
    double? lng,
  });
}
