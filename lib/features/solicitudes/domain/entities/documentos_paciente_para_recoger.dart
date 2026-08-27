/// HU-07/HU-09 — cédula del Paciente (ambos lados), que el Domiciliario
/// necesita mostrar en la farmacia al reclamar el medicamento a su
/// nombre. Solo existe mientras el pedido está en curso de recogida —
/// ver comentario en `ObtenerDocumentosPacienteParaRecogerUseCase`.
class DocumentosPacienteParaRecoger {
  const DocumentosPacienteParaRecoger({
    required this.cedulaFrenteUrl,
    required this.cedulaReversoUrl,
  });

  final String? cedulaFrenteUrl;
  final String? cedulaReversoUrl;

  factory DocumentosPacienteParaRecoger.fromJson(Map<String, dynamic> json) {
    return DocumentosPacienteParaRecoger(
      cedulaFrenteUrl: json['cedulaFrenteUrl'] as String?,
      cedulaReversoUrl: json['cedulaReversoUrl'] as String?,
    );
  }
}
