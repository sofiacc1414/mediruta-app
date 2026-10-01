import 'mensaje_chat.dart';

/// Respuesta de `GET /chat/pedido/:solicitudId` — el chat de un pedido
/// más su histórico completo. `soloLectura` viene calculado por la API
/// (ventana de 30 min tras `entregado`/`cancelada`) — la App no
/// reinventa esa regla, solo la muestra.
class ChatPedido {
  const ChatPedido({
    required this.chatId,
    required this.soloLectura,
    required this.mensajes,
  });

  final String chatId;
  final bool soloLectura;
  final List<MensajeChat> mensajes;

  factory ChatPedido.fromJson(Map<String, dynamic> json) {
    final lista = json['mensajes'] as List<dynamic>;
    return ChatPedido(
      chatId: json['chatId'] as String,
      soloLectura: json['soloLectura'] == true,
      mensajes: lista
          .map((item) => MensajeChat.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
