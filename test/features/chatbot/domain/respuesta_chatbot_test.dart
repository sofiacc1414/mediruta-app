import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/chatbot/domain/respuesta_chatbot.dart';

void main() {
  group('RespuestaChatbot.fromJson', () {
    test('mapea todos los campos', () {
      final respuesta = RespuestaChatbot.fromJson({
        'intencion': 'copago_eps',
        'score': 0.95,
        'respuesta': 'texto de prueba',
        'requiereDatos': 'datos_copago',
        'ofrecerSoporte': false,
      });

      expect(respuesta.intencion, 'copago_eps');
      expect(respuesta.score, 0.95);
      expect(respuesta.respuesta, 'texto de prueba');
      expect(respuesta.requiereDatos, 'datos_copago');
      expect(respuesta.ofrecerSoporte, false);
    });

    test('requiereDatos ausente queda null, ofrecerSoporte ausente queda false', () {
      final respuesta = RespuestaChatbot.fromJson({
        'intencion': 'desconocido',
        'score': 0.0,
        'respuesta': 'no entendí',
      });

      expect(respuesta.requiereDatos, isNull);
      expect(respuesta.ofrecerSoporte, false);
    });
  });
}
