/// Catálogo propio de MediRuta (no el copago real de EPS, que depende
/// de tarifas privadas EPS-IPS que no tenemos forma de conocer) — un
/// valor fijo en COP por nivel, autodeclarado por el Paciente en su
/// perfil.
class NivelCopago {
  const NivelCopago({
    required this.id,
    required this.nombre,
    required this.copago,
    required this.orden,
  });

  final String id;
  final String nombre;
  final num copago;
  final int orden;

  factory NivelCopago.fromJson(Map<String, dynamic> json) {
    return NivelCopago(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      copago: json['copago'] as num,
      orden: json['orden'] as int,
    );
  }
}
