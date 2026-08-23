/// Una línea de medicamento dentro de una solicitud — una fórmula real
/// puede traer varios, no uno solo. Todos opcionales a propósito: una
/// línea puede estar a medio llenar en un Borrador.
class Medicamento {
  const Medicamento({
    this.nombre,
    this.concentracion,
    this.formaFarmaceutica,
    this.cantidad,
    this.posologia,
  });

  final String? nombre;
  final String? concentracion;
  final String? formaFarmaceutica;
  final String? cantidad;
  final String? posologia;

  bool get estaVacio =>
      (nombre == null || nombre!.trim().isEmpty) &&
      (concentracion == null || concentracion!.trim().isEmpty) &&
      (formaFarmaceutica == null || formaFarmaceutica!.trim().isEmpty) &&
      (cantidad == null || cantidad!.trim().isEmpty) &&
      (posologia == null || posologia!.trim().isEmpty);

  bool get estaCompleto =>
      (nombre?.trim().isNotEmpty ?? false) &&
      (concentracion?.trim().isNotEmpty ?? false) &&
      (formaFarmaceutica?.trim().isNotEmpty ?? false) &&
      (cantidad?.trim().isNotEmpty ?? false) &&
      (posologia?.trim().isNotEmpty ?? false);

  Medicamento copyWith({
    String? nombre,
    String? concentracion,
    String? formaFarmaceutica,
    String? cantidad,
    String? posologia,
  }) {
    return Medicamento(
      nombre: nombre ?? this.nombre,
      concentracion: concentracion ?? this.concentracion,
      formaFarmaceutica: formaFarmaceutica ?? this.formaFarmaceutica,
      cantidad: cantidad ?? this.cantidad,
      posologia: posologia ?? this.posologia,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'concentracion': concentracion,
      'formaFarmaceutica': formaFarmaceutica,
      'cantidad': cantidad,
      'posologia': posologia,
    };
  }

  factory Medicamento.fromJson(Map<String, dynamic> json) {
    return Medicamento(
      nombre: json['nombre'] as String?,
      concentracion: json['concentracion'] as String?,
      formaFarmaceutica: json['formaFarmaceutica'] as String?,
      cantidad: json['cantidad'] as String?,
      posologia: json['posologia'] as String?,
    );
  }
}
