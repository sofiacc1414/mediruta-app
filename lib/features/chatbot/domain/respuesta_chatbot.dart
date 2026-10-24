/// Una opción clicable que ofrece el bot cuando no está seguro de
/// haber entendido del todo, pero encontró una intención candidata
/// razonable. Tocarla reenvía el mensaje original con `intencion`
/// como `intencionForzada`.
class SugerenciaChatbot {
  const SugerenciaChatbot({required this.intencion, required this.etiqueta});

  final String intencion;
  final String etiqueta;

  factory SugerenciaChatbot.fromJson(Map<String, dynamic> json) {
    return SugerenciaChatbot(
      intencion: json['intencion'] as String,
      etiqueta: json['etiqueta'] as String,
    );
  }
}

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
    required this.sugerencias,
  });

  final String intencion;
  final double score;
  final String respuesta;

  /// `'eps'`, `'datos_copago'`, o `null` si la respuesta ya está completa.
  final String? requiereDatos;

  /// CA3: tras 2 preguntas sin entender seguidas, mostrar un botón
  /// directo a soporte humano, no solo el texto de la respuesta.
  final bool ofrecerSoporte;

  /// Cuando el bot no está seguro, candidatos razonables para ofrecer
  /// como botones en vez de solo "no entendí". `null` si no hubo
  /// candidatos o si la intención ya se resolvió.
  final List<SugerenciaChatbot>? sugerencias;

  factory RespuestaChatbot.fromJson(Map<String, dynamic> json) {
    final sugerenciasJson = json['sugerencias'] as List<dynamic>?;
    return RespuestaChatbot(
      intencion: json['intencion'] as String,
      score: (json['score'] as num).toDouble(),
      respuesta: json['respuesta'] as String,
      requiereDatos: json['requiereDatos'] as String?,
      ofrecerSoporte: json['ofrecerSoporte'] as bool? ?? false,
      sugerencias: sugerenciasJson
          ?.map((s) => SugerenciaChatbot.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
