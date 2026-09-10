import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../config/app_config.dart';
import 'api_client.dart';

/// Aviso instantáneo de "algo cambió en algún pedido" vía WebSocket (ver
/// `EventosGateway`/`EventosTiempoRealPort` en la API) — reemplaza el
/// poll fijo de 15s que tenían las pantallas: ya no hace falta, porque
/// esto también cubre el caso que cubría el poll (perderse un evento por
/// una desconexión pasajera) reemitiendo al reconectar, ver más abajo.
///
/// El evento (`pedido:actualizado`) no trae datos — cada pantalla que
/// escucha [pedidoActualizado] ya sabe qué volver a pedir para sí misma
/// (mismo criterio que la API: evitar duplicar acá autorización/
/// serialización). Conexión única para toda la app, se abre/cierra desde
/// `AuthSessionNotifier` según haya o no sesión — no tiene sentido
/// mantenerla abierta sin usuario logueado.
class EventosSocketService {
  socket_io.Socket? _socket;
  final _controller = StreamController<void>.broadcast();

  /// Emite (sin dato) cada vez que la API avisa que algún pedido cambió,
  /// y también cada vez que el socket (re)conecta — socket.io-client ya
  /// reintenta solo ante una caída de red, pero cualquier evento
  /// ocurrido mientras estuvo desconectado se habría perdido; refrescar
  /// al reconectar cierra ese hueco sin necesidad de un poll fijo.
  Stream<void> get pedidoActualizado => _controller.stream;

  /// Se conecta con el access token vigente. Idempotente — si ya hay una
  /// conexión abierta (o en curso) no hace nada; para renovar con un
  /// token nuevo hay que `desconectar()` primero.
  Future<void> conectar(ApiClient apiClient) async {
    if (_socket != null) return;

    final token = await apiClient.accessToken;
    if (token == null) return;

    final socket = socket_io.io(
      AppConfig.apiBaseUrl,
      socket_io.OptionBuilder()
          .setPath('/ws')
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    socket.onConnectError((error) {
      debugPrint('EventosSocketService: error de conexión ($error)');
    });
    // `onConnect` dispara tanto en la primera conexión como en cada
    // reconexión automática — en ambos casos vale la pena refrescar.
    socket.onConnect((_) => _controller.add(null));
    socket.on('pedido:actualizado', (_) => _controller.add(null));

    _socket = socket;
    socket.connect();
  }

  /// Cierra la conexión (ej. al cerrar sesión) — nunca lanza aunque no
  /// hubiera nada conectado.
  void desconectar() {
    _socket?.dispose();
    _socket = null;
  }
}
