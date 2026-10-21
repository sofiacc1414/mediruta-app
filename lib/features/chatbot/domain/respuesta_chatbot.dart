/// `requiereDatos` le dice a la pantalla qué le falta pedir al usuario
/// antes de poder responder de verdad (CA1: el bot pide explícitamente
/// la EPS o el régimen/rango de ingresos) — se muestran botones de
/// selección rápida y se reenvía el mismo mensaje original junto con
/// esos datos.
class RespuestaChatbot {
  const RespuestaChatbot({
    required this.intencion,
    required this.score,
    required this.respuesta,
    required this.requiereDatos,
    required this.ofrecerSoporte,
  });

  final String intencion;
  final double score;
  final String respuesta;

  /// `'eps'`, `'datos_copago'`, o `null` si la respuesta ya está completa.
  final String? requiereDatos;

  /// CA3: tras 2 preguntas sin entender seguidas, mostrar un botón
  /// directo a soporte humano, no solo el texto de la respuesta.
  final bool ofrecerSoporte;

  factory RespuestaChatbot.fromJson(Map<String, dynamic> json) {
    return RespuestaChatbot(
      intencion: json['intencion'] as String,
      score: (json['score'] as num).toDouble(),
      respuesta: json['respuesta'] as String,
      requiereDatos: json['requiereDatos'] as String?,
      ofrecerSoporte: json['ofrecerSoporte'] as bool? ?? false,
    );
  }
}
