import '../../../shared/core/network/api_client.dart';
import '../domain/chat_pedido.dart';
import '../domain/mensaje_chat.dart';

class ChatRemoteDatasource {
  const ChatRemoteDatasource(this._api);

  final ApiClient _api;

  Future<ChatPedido> obtenerChatDelPedido(String solicitudId) async {
    final respuesta = await _api.get(
      '/chat/pedido/$solicitudId',
      autenticado: true,
    );
    return ChatPedido.fromJson(respuesta as Map<String, dynamic>);
  }

  Future<MensajeChat> enviarMensaje(String chatId, String contenido) async {
    final respuesta = await _api.post(
      '/chat/$chatId/mensajes',
      body: {'contenido': contenido},
      autenticado: true,
    );
    return MensajeChat.fromJson(respuesta as Map<String, dynamic>);
  }

  Future<void> marcarLeido(String chatId) async {
    await _api.post('/chat/$chatId/marcar-leido', autenticado: true);
  }
}
