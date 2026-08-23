import 'medicamento.dart';

/// Los campos editables de una solicitud: la lista de medicamentos +
/// receta (foto, sube aparte con `SubirRecetaUseCase`; acá solo viaja
/// `recetaFechaVencimiento`) + dirección de entrega. Comunes a crear
/// (G01), editar (G04) y al borrador local en progreso.
class DatosSolicitud {
  const DatosSolicitud({
    this.medicamentos = const [],
    this.recetaFechaVencimiento,
    this.direccionEntrega,
  });

  final List<Medicamento> medicamentos;

  /// Fecha hasta la que la receta es válida (NO la de expedición) — es
  /// lo que permite detectar una receta vencida sin abrir la foto.
  final String? recetaFechaVencimiento;
  final String? direccionEntrega;

  /// G05 — mismos requisitos que valida `app.enviar_solicitud` en la API
  /// (la cédula NO se revisa acá: ya se exige antes de poder crear la
  /// solicitud, HU-02). Se usa para deshabilitar "Enviar solicitud"
  /// preventivamente en la UI, incluyendo el chequeo de receta vencida.
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
    final fechaVencimiento = recetaFechaVencimiento;
    if (fechaVencimiento == null || fechaVencimiento.trim().isEmpty) {
      faltantes.add('Fecha de vencimiento de la receta');
    } else {
      final parseada = DateTime.tryParse(fechaVencimiento);
      final hoy = DateTime.now();
      final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
      if (parseada != null && parseada.isBefore(hoySinHora)) {
        faltantes.add('La receta está vencida — sube una foto de una receta vigente');
      }
    }
    if (direccionEntrega == null || direccionEntrega!.trim().isEmpty) {
      faltantes.add('Dirección de entrega');
    }
    return faltantes;
  }

  Map<String, dynamic> toJson() {
    return {
      'medicamentos': medicamentos.map((m) => m.toJson()).toList(),
      'recetaFechaVencimiento': recetaFechaVencimiento,
      'direccionEntrega': direccionEntrega,
    };
  }

  factory DatosSolicitud.fromJson(Map<String, dynamic> json) {
    final medicamentosJson = json['medicamentos'] as List<dynamic>? ?? [];
    return DatosSolicitud(
      medicamentos: medicamentosJson
          .map((e) => Medicamento.fromJson(e as Map<String, dynamic>))
          .toList(),
      recetaFechaVencimiento: json['recetaFechaVencimiento'] as String?,
      direccionEntrega: json['direccionEntrega'] as String?,
    );
  }
}
