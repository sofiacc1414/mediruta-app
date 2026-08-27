/// Lado de la cédula del Paciente — mismos 2 valores que acepta
/// `app.actualizar_foto_cedula_paciente` en la API. La cédula
/// colombiana trae información necesaria en ambas caras, así que los
/// dos son obligatorios antes de poder enviar una solicitud.
enum LadoDocumento {
  frente,
  reverso;

  /// Valor exacto que espera la API (minúsculas, sin transformar).
  String get valor => name;
}
