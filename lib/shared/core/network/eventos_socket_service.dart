import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../config/app_config.dart';
import 'api_client.dart';

/// "timeout"/"xhr poll error" son mensajes genéricos de socket.io — acá
/// abajo casi siempre hay una `SocketException` de Dart con el error
/// real del sistema operativo (`osError`: "Connection timed out",
/// "Network is unreachable", un fallo de TLS, etc.), que es lo que de
/// verdad ayuda a diagnosticar. Temporal, ver doc de [FaseSocket].
String _detalleCompletoDe(Object error) {
  final base = '${error.runtimeType}: $error';
  if (error is SocketException && error.osError != null) {
    return '$base (osError: ${error.osError})';
  }
  return base;
}

/// Fase de la conexión — ver [EventosSocketService.diagnostico], que
/// alimenta el punto de color de `IndicadorConexion` en Home (antes,
/// mientras se investigaba el bug del transporte de polling, una
/// tarjeta completa con el detalle técnico — ya no hace falta con la
/// causa encontrada y corregida).
enum FaseSocket { desconectado, conectando, conectado, error }

class DiagnosticoSocket {
  const DiagnosticoSocket({required this.fase, this.detalle, this.intentos = 0});

  final FaseSocket fase;
  final String? detalle;
  final int intentos;

  DiagnosticoSocket copyWith({FaseSocket? fase, String? detalle, int? intentos}) {
    return DiagnosticoSocket(
      fase: fase ?? this.fase,
      // `detalle` se limpia explícitamente pasando null solo cuando
      // fase se especifica (ej. al reconectar bien) — si no, se
      // conserva el último mensaje.
      detalle: fase != null ? detalle : (detalle ?? this.detalle),
      intentos: intentos ?? this.intentos,
    );
  }
}

/// Aviso instantáneo de "algo cambió en algún pedido" vía WebSocket (ver
/// `EventosGateway`/`EventosTiempoRealPort` en la API) — pensado para
/// complementar el poll de 15s que siguen teniendo las pantallas (ver
/// `_intervaloPoll` en cada una): cuando el socket conecta bien, avisa
/// al instante; cuando no, el poll sigue cubriendo.
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

  /// Estado de la conexión en vivo — alimenta `IndicadorConexion` en
  /// Home. `ValueNotifier` en vez de `Stream` porque a la UI le
  /// interesa el último valor, no solo los cambios.
  final ValueNotifier<DiagnosticoSocket> diagnostico = ValueNotifier(
    const DiagnosticoSocket(fase: FaseSocket.desconectado),
  );

  /// Emite (sin dato) cada vez que la API avisa que algún pedido cambió,
  /// y también cada vez que el socket (re)conecta — socket.io-client ya
  /// reintenta solo ante una caída de red, pero cualquier evento
  /// ocurrido mientras estuvo desconectado se habría perdido; refrescar
  /// al reconectar cierra ese hueco.
  Stream<void> get pedidoActualizado => _controller.stream;

  /// Se conecta con el access token vigente. Idempotente — si ya hay una
  /// conexión abierta (o en curso) no hace nada; para renovar con un
  /// token nuevo hay que `desconectar()` primero.
  Future<void> conectar(ApiClient apiClient) async {
    if (_socket != null) return;

    final token = await apiClient.accessToken;
    if (token == null) return;

    diagnostico.value = const DiagnosticoSocket(fase: FaseSocket.conectando);

    final socket = socket_io.io(
      AppConfig.apiBaseUrl,
      socket_io.OptionBuilder()
          .setPath('/ws')
          // Transporte 'websocket' puro, sin el polling HTTP inicial
          // de socket.io — confirmado en vivo (Redmi Note 15/HyperOS,
          // logcat + comparación con Chrome) que el polling del
          // paquete `socket_io_client` de Dart nunca completaba el
          // handshake en ese dispositivo (timeout puro, sin excepción
          // de red por debajo — ver `_detalleCompletoDe`), mientras
          // que Chrome (otro motor HTTP) sí conectaba al toque al
          // mismo endpoint. Saltar el polling y usar WebSocket.connect()
          // nativo de dart:io resolvió la conexión en esa prueba.
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .setTimeout(45000)
          .build(),
    );

    socket.onConnectError((error) {
      final detalle = error is Object ? _detalleCompletoDe(error) : '$error';
      debugPrint('EventosSocketService: error de conexión ($detalle)');
      diagnostico.value = DiagnosticoSocket(
        fase: FaseSocket.error,
        detalle: 'connect_error: $detalle',
        intentos: diagnostico.value.intentos + 1,
      );
    });
    socket.onDisconnect((reason) {
      debugPrint('EventosSocketService: desconectado ($reason)');
      diagnostico.value = DiagnosticoSocket(
        fase: FaseSocket.desconectado,
        detalle: 'disconnect: $reason',
        intentos: diagnostico.value.intentos,
      );
    });
    socket.onReconnectAttempt((intento) {
      diagnostico.value = diagnostico.value.copyWith(
        fase: FaseSocket.conectando,
        intentos: diagnostico.value.intentos + 1,
      );
    });
    // `onConnect` dispara tanto en la primera conexión como en cada
    // reconexión automática — en ambos casos vale la pena refrescar.
    socket.onConnect((_) {
      diagnostico.value = DiagnosticoSocket(
        fase: FaseSocket.conectado,
        intentos: diagnostico.value.intentos,
      );
      _controller.add(null);
    });
    socket.on('pedido:actualizado', (_) => _controller.add(null));

    _socket = socket;
    socket.connect();
  }

  /// Cierra la conexión (ej. al cerrar sesión) — nunca lanza aunque no
  /// hubiera nada conectado.
  void desconectar() {
    _socket?.dispose();
    _socket = null;
    diagnostico.value = const DiagnosticoSocket(fase: FaseSocket.desconectado);
  }
}
