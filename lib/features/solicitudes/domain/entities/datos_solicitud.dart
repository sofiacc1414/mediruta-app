import 'medicamento.dart';

/// Los campos editables de una solicitud: la lista de medicamentos +
/// receta (foto, sube aparte con `SubirRecetaUseCase`; acá solo viaja
/// `recetaFechaExpedicion`) + dirección de entrega. Comunes a crear
/// (G01), editar (G04) y al borrador local en progreso.
class DatosSolicitud {
  const DatosSolicitud({
    this.medicamentos = const [],
    this.recetaFechaExpedicion,
    this.direccionEntrega,
  });

  final List<Medicamento> medicamentos;
  final String? recetaFechaExpedicion;
  final String? direccionEntrega;

  /// G05 — mismos 4 requisitos que valida `app.enviar_solicitud` en la
  /// API (la cédula NO se revisa acá: ya se exige antes de poder crear
  /// la solicitud, HU-02). Se usa para deshabilitar "Enviar solicitud"
  /// preventivamente en la UI.
  List<String> calcularFaltantes({required bool tieneRecetaSubida}) {
    final medicamentosNoVacios = medicamentos.where((m) => !m.estaVacio).toList();
    final faltantes = <String>[];

    if (medicamentosNoVacios.isEmpty) {
      faltantes.add('Al menos un medicamento');
    } else if (medicamentosNoVacios.any((m) => !m.estaCompleto)) {
      faltantes.add('Completar todos los campos de cada medicamento');
    }
    if (!tieneRecetaSubida) {
      faltantes.add('Foto de la receta');
    }
    if (recetaFechaExpedicion == null || recetaFechaExpedicion!.trim().isEmpty) {
      faltantes.add('Fecha de expedición de la receta');
    }
    if (direccionEntrega == null || direccionEntrega!.trim().isEmpty) {
      faltantes.add('Dirección de entrega');
    }
    return faltantes;
  }

  Map<String, dynamic> toJson() {
    return {
      'medicamentos': medicamentos.map((m) => m.toJson()).toList(),
      'recetaFechaExpedicion': recetaFechaExpedicion,
      'direccionEntrega': direccionEntrega,
    };
  }

  factory DatosSolicitud.fromJson(Map<String, dynamic> json) {
    final medicamentosJson = json['medicamentos'] as List<dynamic>? ?? [];
    return DatosSolicitud(
      medicamentos: medicamentosJson
          .map((e) => Medicamento.fromJson(e as Map<String, dynamic>))
          .toList(),
      recetaFechaExpedicion: json['recetaFechaExpedicion'] as String?,
      direccionEntrega: json['direccionEntrega'] as String?,
    );
  }
}
