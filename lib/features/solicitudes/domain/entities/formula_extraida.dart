import 'medicamento.dart';

/// Módulo 1 (OCR) — lo que `POST /formulas/extraer` devuelve al leer
/// una foto/PDF de fórmula médica. Las fechas llegan en ISO 8601 o
/// `null` si el OCR no pudo leerlas (igual que `medicamentos` puede
/// venir vacío) — nunca bloquea el flujo, solo precarga lo que se pudo.
class FormulaExtraida {
  const FormulaExtraida({
    required this.fechaEmision,
    required this.fechaVencimiento,
    required this.farmaciaIpsOrigen,
    required this.medicamentos,
  });

  final String? fechaEmision;

  /// Fecha de vencimiento tal cual la imprime la fórmula (ej. "Fecha de
  /// vencimiento: 22 Abr 2025") — no es una inferencia a partir de
  /// `fechaEmision`, es el dato real cuando el documento lo trae.
  final String? fechaVencimiento;
  final String? farmaciaIpsOrigen;
  final List<Medicamento> medicamentos;

  factory FormulaExtraida.fromJson(Map<String, dynamic> json) {
    final medicamentosJson = json['medicamentos'] as List<dynamic>? ?? [];
    return FormulaExtraida(
      fechaEmision: json['fechaEmision'] as String?,
      fechaVencimiento: json['fechaVencimiento'] as String?,
      farmaciaIpsOrigen: json['farmaciaIpsOrigen'] as String?,
      medicamentos: medicamentosJson
          .map((e) => Medicamento.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
