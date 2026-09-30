import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/core/network/api_exception.dart';
import '../../../shared/core/network/chat_socket_service.dart';
import '../../../shared/core/theme/app_colors.dart';
import '../../../shared/widgets/app_error_banner.dart';
import '../../usuarios/presentation/providers/auth_session_provider.dart';
import '../../usuarios/presentation/providers/usuario_providers.dart';
import '../domain/mensaje_chat.dart';
import 'chat_provider.dart';

/// Chat en tiempo real Paciente↔Domiciliario de un pedido. Se accede
/// desde `SolicitudDetalleScreen` (Paciente) y `MiPedidoActivoScreen`
/// (Domiciliario) pasando el `solicitudId` — la pantalla no reinventa
/// ninguna regla de negocio (quién puede entrar, cuándo pasa a solo
/// lectura): todo eso lo decide la API y acá solo se muestra.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.solicitudId});

  static const routeName = '/chat';

  final String solicitudId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _socket = ChatSocketService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<MensajeChat>? _suscripcionMensajes;
  StreamSubscription<bool>? _suscripcionEstado;

  bool _cargando = true;
  bool _enviando = false;
  String? _error;
  String? _chatId;
  bool _soloLectura = false;
  List<MensajeChat> _mensajes = const [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _suscripcionMensajes?.cancel();
    _suscripcionEstado?.cancel();
    _socket.desconectar();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final chat = await ref
          .read(chatDatasourceProvider)
          .obtenerChatDelPedido(widget.solicitudId);
      if (!mounted) return;
      setState(() {
        _chatId = chat.chatId;
        _soloLectura = chat.soloLectura;
        _mensajes = chat.mensajes;
        _cargando = false;
      });
      unawaited(ref.read(chatDatasourceProvider).marcarLeido(chat.chatId));
      _conectarSocket();
      _irAlFinal();
    } on ApiException catch (error) {
      setState(() {
        _error = _mensajeError(error);
        _cargando = false;
      });
    } on ApiSinConexionException catch (error) {
      setState(() {
        _error = error.toString();
        _cargando = false;
      });
    }
  }

  String _mensajeError(ApiException error) {
    if (error.message.contains('ChatSinDomiciliarioAsignadoError') ||
        error.message.toLowerCase().contains('domiciliario asignado')) {
      return 'Todavía no hay un domiciliario asignado a este pedido — el chat se habilita en cuanto lo haya.';
    }
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'No podés acceder al chat de este pedido.';
    }
    return 'No se pudo abrir el chat. Intenta de nuevo.';
  }

  void _conectarSocket() {
    _suscripcionMensajes = _socket.mensajeNuevo.listen((mensaje) {
      if (!mounted) return;
      if (_mensajes.any((existente) => existente.id == mensaje.id)) return;
      setState(() => _mensajes = [..._mensajes, mensaje]);
      _irAlFinal();
      if (mensaje.remitenteId != _miUsuarioId()) {
        unawaited(
          ref.read(chatDatasourceProvider).marcarLeido(mensaje.chatId).catchError(
                (_) {},
              ),
        );
      }
    });
    _suscripcionEstado = _socket.cambioSoloLectura.listen((soloLectura) {
      if (!mounted) return;
      setState(() => _soloLectura = soloLectura);
    });
    unawaited(_socket.conectarYUnirse(ref.read(apiClientProvider), widget.solicitudId));
  }

  String? _miUsuarioId() {
    final estado = ref.read(authSessionProvider);
    return estado is AuthAutenticado ? estado.usuario.id : null;
  }

  void _irAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _enviar() async {
    final chatId = _chatId;
    final contenido = _controller.text.trim();
    if (chatId == null || contenido.isEmpty || _soloLectura || _enviando) return;

    setState(() => _enviando = true);
    _controller.clear();
    try {
      // Vía WebSocket cuando está conectado (más rápido, llega a la
      // otra punta al instante); si el socket falló, se cae al REST —
      // ambos caminos pasan por el mismo `EnviarMensajeChatUseCase` del
      // lado de la API, así que el resultado es idéntico.
      final mensaje = await ref
          .read(chatDatasourceProvider)
          .enviarMensaje(chatId, contenido);
      _socket.enviarMensaje(chatId, contenido);
      if (!mounted) return;
      if (!_mensajes.any((existente) => existente.id == mensaje.id)) {
        setState(() => _mensajes = [..._mensajes, mensaje]);
        _irAlFinal();
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 409) {
        setState(() => _soloLectura = true);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mensajeEnvioError(error))),
      );
    } on ApiSinConexionException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String _mensajeEnvioError(ApiException error) {
    if (error.statusCode == 409) {
      return 'Este chat ya no acepta mensajes nuevos.';
    }
    return 'No se pudo enviar el mensaje. Intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Chat del pedido',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.navy),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.navy, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: AppErrorBanner(mensaje: _error!),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: _mensajes.isEmpty
                                ? const _ChatVacio()
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                    itemCount: _mensajes.length,
                                    itemBuilder: (context, index) => _BurbujaMensaje(
                                      mensaje: _mensajes[index],
                                      esPropio: _mensajes[index].remitenteId == _miUsuarioId(),
                                    ),
                                  ),
                          ),
                          if (_soloLectura)
                            const _AvisoSoloLectura()
                          else
                            _CampoEnvio(
                              controller: _controller,
                              enviando: _enviando,
                              onEnviar: _enviar,
                            ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}

class _ChatVacio extends StatelessWidget {
  const _ChatVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.teal.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'Escribile a la otra persona sobre este pedido.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.teal, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _BurbujaMensaje extends StatelessWidget {
  const _BurbujaMensaje({required this.mensaje, required this.esPropio});

  final MensajeChat mensaje;
  final bool esPropio;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: esPropio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: esPropio ? AppColors.teal : AppColors.skyBlue.withValues(alpha: 0.55),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(esPropio ? 16 : 4),
            bottomRight: Radius.circular(esPropio ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensaje.contenido,
              style: TextStyle(
                color: esPropio ? AppColors.white : AppColors.navy,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _hora(mensaje.creadoEn),
                  style: TextStyle(
                    color: (esPropio ? AppColors.white : AppColors.navy).withValues(alpha: 0.65),
                    fontSize: 10,
                  ),
                ),
                if (esPropio) ...[
                  const SizedBox(width: 4),
                  Icon(
                    mensaje.leidoEn != null ? Icons.done_all : Icons.done,
                    size: 13,
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _hora(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.hour)}:${dos(fecha.minute)}';
  }
}

class _AvisoSoloLectura extends StatelessWidget {
  const _AvisoSoloLectura();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.skyBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navy, width: 1.2),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, color: AppColors.navy, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este chat ya no acepta mensajes nuevos — el pedido se cerró hace más de 30 minutos.',
              style: TextStyle(color: AppColors.navy, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoEnvio extends StatelessWidget {
  const _CampoEnvio({
    required this.controller,
    required this.enviando,
    required this.onEnviar,
  });

  final TextEditingController controller;
  final bool enviando;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onEnviar(),
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje…',
                filled: true,
                fillColor: AppColors.beige.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: enviando ? null : onEnviar,
            style: IconButton.styleFrom(backgroundColor: AppColors.navy),
            icon: enviando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                  )
                : const Icon(Icons.send_rounded, color: AppColors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
