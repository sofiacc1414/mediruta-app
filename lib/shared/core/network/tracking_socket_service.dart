import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../../../features/tracking/domain/posicion_en_vivo.dart';
import '../config/app_config.dart';
import 'api_client.dart';

/// WebSocket dedicado al seguimiento GPS en vivo (`TrackingGateway`,
/// path `/ws-tracking`) — mismo patrón que `EventosSocketService` pero
/// de ciclo de vida por pantalla (se conecta al abrir el mapa, se
/// desconecta al salir), igual que un chat. `.enableForceNew()` es
/// obligatorio: `socket_io_client` reutiliza la conexión por host/
/// puerto si no se fuerza una nueva, y eso puede terminar compartiendo
/// el socket con `EventosSocketService` (mismo `AppConfig.apiBaseUrl`).
class TrackingSocketService {
  socket_io.Socket? _socket;
  final _posicionInicialController = StreamController<PosicionEnVivo>.broadcast();
  final _posicionController = StreamController<PosicionActualizada>.broadcast();
  final _finalizadoController = StreamController<void>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<PosicionEnVivo> get posicionInicial => _posicionInicialController.stream;
  Stream<PosicionActualizada> get posicionNueva => _posicionController.stream;
  Stream<void> get finalizado => _finalizadoController.stream;
  Stream<String> get error => _errorController.stream;

  Future<void> conectarYSuscribir(ApiClient apiClient, String solicitudId) async {
    if (_socket != null) return;
    final token = await apiClient.accessToken;
    if (token == null) return;

    final socket = socket_io.io(
      AppConfig.apiBaseUrl,
      socket_io.OptionBuilder()
          .setPath('/ws-tracking')
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .setTimeout(45000)
          .enableForceNew()
          .build(),
    );

    socket.onConnect((_) => socket.emit('tracking:suscribir', {'solicitudId': solicitudId}));
    socket.on(
      'tracking:posicion_inicial',
      (data) => _posicionInicialController.add(
        PosicionEnVivo.fromJson(Map<String, dynamic>.from(data as Map)),
      ),
    );
    socket.on(
      'tracking:posicion',
      (data) => _posicionController.add(
        PosicionActualizada.fromJson(Map<String, dynamic>.from(data as Map)),
      ),
    );
    socket.on('tracking:finalizado', (_) => _finalizadoController.add(null));
    socket.on(
      'tracking:error',
      (data) => _errorController.add((data as Map)['motivo']?.toString() ?? 'error'),
    );

    _socket = socket;
    socket.connect();
  }

  /// Solo el domiciliario la llama — el filtro de 10m/15s vive en
  /// quien la invoca (`MiPedidoActivoScreen`), acá solo se emite.
  void enviarPosicion(String solicitudId, double lat, double lng) {
    _socket?.emit('tracking:enviar_posicion', {'solicitudId': solicitudId, 'lat': lat, 'lng': lng});
  }

  void desconectar() {
    _socket?.dispose();
    _socket = null;
  }
}
