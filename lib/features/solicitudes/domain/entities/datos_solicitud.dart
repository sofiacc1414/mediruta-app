/// Los 10 campos editables de una solicitud (medicamento + receta +
/// dirección de entrega) — comunes a crear (G01), editar (G04) y al
/// borrador local en progreso. Todos opcionales a propósito: un Borrador
/// puede estar incompleto, se completa de a poco.
class DatosSolicitud {
  const DatosSolicitud({
    this.medicamentoNombre,
    this.medicamentoConcentracion,
    this.medicamentoFormaFarmaceutica,
    this.medicamentoCantidad,
    this.medicamentoPosologia,
    this.recetaMedicoNombre,
    this.recetaMedicoRegistro,
    this.recetaIps,
    this.recetaFechaExpedicion,
    this.direccionEntrega,
  });

  final String? medicamentoNombre;
  final String? medicamentoConcentracion;
  final String? medicamentoFormaFarmaceutica;
  final String? medicamentoCantidad;
  final String? medicamentoPosologia;
  final String? recetaMedicoNombre;
  final String? recetaMedicoRegistro;
  final String? recetaIps;
  final String? recetaFechaExpedicion;
  final String? direccionEntrega;

  /// G05 — mismos 10 requisitos que valida `app.enviar_solicitud` en la
  /// API, en el mismo orden y con las mismas etiquetas — se usa para
  /// deshabilitar "Enviar solicitud" preventivamente en la UI.
  List<String> calcularFaltantes() {
    final requisitos = <String, String?>{
      'Nombre del medicamento': medicamentoNombre,
      'Concentración/dosis': medicamentoConcentracion,
      'Forma farmacéutica': medicamentoFormaFarmaceutica,
      'Cantidad solicitada': medicamentoCantidad,
      'Posología': medicamentoPosologia,
      'Nombre del médico': recetaMedicoNombre,
      'Registro médico': recetaMedicoRegistro,
      'IPS': recetaIps,
      'Fecha de expedición de la receta': recetaFechaExpedicion,
      'Dirección de entrega': direccionEntrega,
    };
    return [
      for (final entrada in requisitos.entries)
        if (entrada.value == null || entrada.value!.trim().isEmpty) entrada.key,
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'medicamentoNombre': medicamentoNombre,
      'medicamentoConcentracion': medicamentoConcentracion,
      'medicamentoFormaFarmaceutica': medicamentoFormaFarmaceutica,
      'medicamentoCantidad': medicamentoCantidad,
      'medicamentoPosologia': medicamentoPosologia,
      'recetaMedicoNombre': recetaMedicoNombre,
      'recetaMedicoRegistro': recetaMedicoRegistro,
      'recetaIps': recetaIps,
      'recetaFechaExpedicion': recetaFechaExpedicion,
      'direccionEntrega': direccionEntrega,
    };
  }

  factory DatosSolicitud.fromJson(Map<String, dynamic> json) {
    return DatosSolicitud(
      medicamentoNombre: json['medicamentoNombre'] as String?,
      medicamentoConcentracion: json['medicamentoConcentracion'] as String?,
      medicamentoFormaFarmaceutica: json['medicamentoFormaFarmaceutica'] as String?,
      medicamentoCantidad: json['medicamentoCantidad'] as String?,
      medicamentoPosologia: json['medicamentoPosologia'] as String?,
      recetaMedicoNombre: json['recetaMedicoNombre'] as String?,
      recetaMedicoRegistro: json['recetaMedicoRegistro'] as String?,
      recetaIps: json['recetaIps'] as String?,
      recetaFechaExpedicion: json['recetaFechaExpedicion'] as String?,
      direccionEntrega: json['direccionEntrega'] as String?,
    );
  }
}
