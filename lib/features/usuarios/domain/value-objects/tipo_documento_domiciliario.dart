/// Tipos de documento del Domiciliario (HU-02) — mismos valores que
/// acepta `app.actualizar_documento_domiciliario` en la API. La cédula
/// se pide en 2 lados (frente/reverso) porque la cédula colombiana
/// trae información necesaria en ambas caras.
enum TipoDocumentoDomiciliario {
  cedulaFrente,
  cedulaReverso,
  licencia,
  soat,
  tecnicomecanica;

  /// Valor exacto que espera la API (snake_case para los que lo
  /// necesitan, minúsculas simples para el resto).
  String get valor => switch (this) {
    TipoDocumentoDomiciliario.cedulaFrente => 'cedula_frente',
    TipoDocumentoDomiciliario.cedulaReverso => 'cedula_reverso',
    TipoDocumentoDomiciliario.licencia => 'licencia',
    TipoDocumentoDomiciliario.soat => 'soat',
    TipoDocumentoDomiciliario.tecnicomecanica => 'tecnicomecanica',
  };
}
