/// Tipos de documento del Domiciliario (HU-02) — mismos 4 valores que
/// acepta `app.actualizar_documento_domiciliario` en la API.
enum TipoDocumentoDomiciliario {
  cedula,
  licencia,
  soat,
  tecnicomecanica;

  /// Valor exacto que espera la API (minúsculas, sin transformar).
  String get valor => name;
}
