import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../config/app_config.dart';
import 'api_client.dart';

/// Fase de la conexión — ver [EventosSocketService.diagnostico].
/// Temporal, para diagnosticar en vivo por qué el WebSocket no conecta
/// en algunas redes (ver `DiagnosticoConexionCard`) — no es algo que
/// vaya a quedar como feature permanente.
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

  /// Estado de la conexión en vivo — temporal, para diagnosticar por
  /// qué el socket no conecta en ciertas redes (ver
  /// `DiagnosticoConexionCard`, mostrada en Home mientras se investiga
  /// esto). `ValueNotifier` en vez de `Stream` porque a la UI le
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
          // Sin restringir transportes a solo 'websocket': el cliente
          // arranca con polling HTTP (que ya sabemos que pasa por el
          // proxy de Render sin problema) y recién ahí sube a
          // websocket — el default de socket.io. Forzar 'websocket'
          // desde el arranque salta ese handshake inicial y en la
          // práctica no conecta en varias redes móviles (NAT/proxies
          // que no dejan pasar un upgrade a WS como primer request).
          .setAuth({'token': token})
          .disableAutoConnect()
          // Render (plan free) duerme el servicio tras ~15min sin
          // requests y puede tardar 30-50s en despertar en el primer
          // request — un request HTTP normal simplemente se siente
          // lento, pero el handshake del WS tiene su propio timeout
          // (20s por defecto) y expiraba antes de que el servicio
          // terminara de levantar, viéndose como "timeout" repetido.
          // Se sube a 45s para darle margen a ese arranque en frío.
          .setTimeout(45000)
          .build(),
    );

    socket.onConnectError((error) {
      debugPrint('EventosSocketService: error de conexión ($error)');
      diagnostico.value = DiagnosticoSocket(
        fase: FaseSocket.error,
        detalle: 'connect_error: $error',
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
