import '../../../shared/core/network/api_client.dart';
import '../domain/respuesta_chatbot.dart';

class ChatbotRemoteDatasource {
  const ChatbotRemoteDatasource(this._api);

  final ApiClient _api;

  Future<RespuestaChatbot> enviarMensaje(
    String mensaje, {
    String? eps,
    String? regimen,
    String? rangoIngresos,
    int intentosSinExitoSeguidos = 0,
    String? intencionForzada,
  }) async {
    final respuesta = await _api.post(
      '/chatbot/mensaje',
      body: {
        'mensaje': mensaje,
        if (eps != null) 'eps': eps,
        if (regimen != null) 'regimen': regimen,
        if (rangoIngresos != null) 'rangoIngresos': rangoIngresos,
        'intentosSinExitoSeguidos': intentosSinExitoSeguidos,
        if (intencionForzada != null) 'intencionForzada': intencionForzada,
      },
      autenticado: true,
    );
    return RespuestaChatbot.fromJson(respuesta as Map<String, dynamic>);
  }
}
