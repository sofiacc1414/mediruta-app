import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../../../features/chat/domain/mensaje_chat.dart';
import '../config/app_config.dart';
import 'api_client.dart';

/// WebSocket dedicado al chat (`ChatGateway`, path `/ws-chat`) —
/// hermano de [EventosSocketService] pero de ciclo de vida por
/// pantalla: se conecta al abrir `ChatScreen` y se desconecta al
/// salir, en vez de vivir mientras dura la sesión. Cada instancia
/// habla de UN chat a la vez (se une a su room con `chat:join`).
class ChatSocketService {
  socket_io.Socket? _socket;
  final _mensajeController = StreamController<MensajeChat>.broadcast();
  final _cambioEstadoController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<MensajeChat> get mensajeNuevo => _mensajeController.stream;

  /// Emite `true` cuando la API avisa que el chat pasó a solo-lectura
  /// (venció la ventana de 30 min) mientras la pantalla está abierta.
  Stream<bool> get cambioSoloLectura => _cambioEstadoController.stream;

  Stream<String> get error => _errorController.stream;

  Future<void> conectarYUnirse(ApiClient apiClient, String solicitudId) async {
    if (_socket != null) return;
    final token = await apiClient.accessToken;
    if (token == null) return;

    final socket = socket_io.io(
      AppConfig.apiBaseUrl,
      socket_io.OptionBuilder()
          .setPath('/ws-chat')
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .setTimeout(45000)
          // `socket_io_client` multiplexa por scheme/host/port (ver
          // `io()` en socket_io_client.dart) — sin esto, esta conexión
          // puede terminar compartiendo el Manager/Socket interno con
          // `EventosSocketService` (misma `AppConfig.apiBaseUrl`), pese
          // a pasarle un `path` distinto acá. Bug real reportado: los
          // mensajes no llegaban en vivo porque el join a `/ws-chat`
          // nunca se completaba como conexión propia.
          .enableForceNew()
          .build(),
    );

    socket.onConnect((_) => socket.emit('chat:join', {'solicitudId': solicitudId}));
    socket.on(
      'chat:nuevo_mensaje',
      (data) => _mensajeController.add(
        MensajeChat.fromJson(Map<String, dynamic>.from(data as Map)),
      ),
    );
    socket.on(
      'chat:cambio_estado',
      (data) => _cambioEstadoController.add(
        (data as Map)['soloLectura'] == true,
      ),
    );
    socket.on(
      'chat:error',
      (data) => _errorController.add((data as Map)['motivo']?.toString() ?? 'error'),
    );

    _socket = socket;
    socket.connect();
  }

  void enviarMensaje(String chatId, String contenido) {
    _socket?.emit('chat:enviar_mensaje', {'chatId': chatId, 'contenido': contenido});
  }

  void desconectar() {
    _socket?.dispose();
    _socket = null;
  }
}
