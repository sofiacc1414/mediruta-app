import 'package:flutter_test/flutter_test.dart';

import 'package:mediruta_app/features/chat/domain/chat_pedido.dart';
import 'package:mediruta_app/features/chat/domain/mensaje_chat.dart';

void main() {
  test('MensajeChat.fromJson parsea un mensaje leído', () {
    final mensaje = MensajeChat.fromJson({
      'id': 'msg-1',
      'chatId': 'chat-1',
      'remitenteId': 'paciente-1',
      'rolRemitente': 'PACIENTE',
      'contenido': 'Ya salgo para la farmacia',
      'creadoEn': '2026-09-30T10:00:00.000Z',
      'leidoEn': '2026-09-30T10:05:00.000Z',
    });

    expect(mensaje.id, 'msg-1');
    expect(mensaje.rolRemitente, 'PACIENTE');
    expect(mensaje.leidoEn, isNotNull);
  });

  test('MensajeChat.fromJson acepta leidoEn null', () {
    final mensaje = MensajeChat.fromJson({
      'id': 'msg-2',
      'chatId': 'chat-1',
      'remitenteId': 'domiciliario-1',
      'rolRemitente': 'DOMICILIARIO',
      'contenido': 'Voy en camino',
      'creadoEn': '2026-09-30T10:10:00.000Z',
      'leidoEn': null,
    });

    expect(mensaje.leidoEn, isNull);
  });

  test('ChatPedido.fromJson parsea el chat con su histórico', () {
    final chat = ChatPedido.fromJson({
      'chatId': 'chat-1',
      'soloLectura': false,
      'mensajes': [
        {
          'id': 'msg-1',
          'chatId': 'chat-1',
          'remitenteId': 'paciente-1',
          'rolRemitente': 'PACIENTE',
          'contenido': 'Hola',
          'creadoEn': '2026-09-30T10:00:00.000Z',
          'leidoEn': null,
        },
      ],
    });

    expect(chat.chatId, 'chat-1');
    expect(chat.soloLectura, isFalse);
    expect(chat.mensajes, hasLength(1));
  });

  test('ChatPedido.fromJson refleja solo-lectura tras vencer la ventana', () {
    final chat = ChatPedido.fromJson({
      'chatId': 'chat-1',
      'soloLectura': true,
      'mensajes': <dynamic>[],
    });

    expect(chat.soloLectura, isTrue);
    expect(chat.mensajes, isEmpty);
  });
}
