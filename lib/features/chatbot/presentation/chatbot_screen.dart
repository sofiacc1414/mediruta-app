import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/core/network/api_exception.dart';
import '../../../shared/core/theme/app_colors.dart';
import 'chatbot_provider.dart';
import '../domain/respuesta_chatbot.dart';
import '../../../shared/core/theme/modo_alto_contraste_provider.dart';
import '../../../shared/core/theme/modo_oscuro_provider.dart';

class _MensajeLocal {
  const _MensajeLocal({required this.texto, required this.esUsuario});
  final String texto;
  final bool esUsuario;
}

/// Qué le falta al bot para responder de verdad (CA1) — mientras está
/// pendiente, no se reclasifica el mensaje: el siguiente toque/envío se
/// manda junto con el dato que falta, sobre la MISMA pregunta original.
class _FlujoPendiente {
  const _FlujoPendiente({required this.tipo, required this.mensajeOriginal, this.regimenElegido});

  /// `'eps'` o `'datos_copago'`.
  final String tipo;
  final String mensajeOriginal;
  final String? regimenElegido;
}

/// Sugerencias ofrecidas sobre un mensaje puntual del bot — se
/// descartan apenas el usuario envía otra cosa (texto nuevo, o elige
/// una de las opciones, que a su vez reenvía el mensaje original con
/// `intencionForzada`).
class _SugerenciasPendientes {
  const _SugerenciasPendientes({
    required this.mensajeOriginal,
    required this.opciones,
  });

  final String mensajeOriginal;
  final List<SugerenciaChatbot> opciones;
}

const _opcionesRango = {
  'menos_2_smlv': 'Menos de 2 SMLV',
  'entre_2_y_5_smlv': 'Entre 2 y 5 SMLV',
  'mas_5_smlv': 'Más de 5 SMLV',
};

/// Módulo 2 — chatbot de preguntas frecuentes (registro, pedidos, chat
/// con el domiciliario, reclamo en farmacia, novedades del pedido,
/// código de entrega, copago, farmacias por EPS, POS/No-POS).
/// Disponible para cualquier usuario autenticado, Paciente o
/// Domiciliario — ver `ChatbotController` del lado de la API.
class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  static const routeName = '/chatbot';

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_MensajeLocal> _mensajes = [
    const _MensajeLocal(
      texto:
          'Hola, soy el asistente de MediRuta. Preguntame sobre registro, contraseña, pedidos, '
          'tarifas y cobros, cancelaciones, el chat con el domiciliario, reclamos en farmacia, '
          'copagos o farmacias de tu EPS.',
      esUsuario: false,
    ),
  ];

  bool _enviando = false;
  int _fallosSeguidos = 0;
  _FlujoPendiente? _pendiente;
  _SugerenciasPendientes? _sugerencias;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _desplazarAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _enviarTexto() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _enviando) return;

    if (_pendiente?.tipo == 'eps') {
      final pendiente = _pendiente!;
      _controller.clear();
      await _enviar(pendiente.mensajeOriginal, eps: texto, mostrarComoMensajeUsuario: texto);
      return;
    }

    _controller.clear();
    await _enviar(texto, mostrarComoMensajeUsuario: texto);
  }

  Future<void> _elegirRegimen(String regimen) async {
    final pendiente = _pendiente;
    if (pendiente == null) return;

    if (regimen == 'subsidiado') {
      await _enviar(
        pendiente.mensajeOriginal,
        regimen: regimen,
        mostrarComoMensajeUsuario: 'Régimen subsidiado',
      );
      return;
    }

    // Contributivo necesita además el rango de ingresos — se queda en
    // el mismo flujo pendiente, ahora pidiendo el rango.
    setState(() {
      _pendiente = _FlujoPendiente(
        tipo: 'datos_copago',
        mensajeOriginal: pendiente.mensajeOriginal,
        regimenElegido: regimen,
      );
      _mensajes.add(const _MensajeLocal(texto: 'Régimen contributivo', esUsuario: true));
    });
    _desplazarAlFinal();
  }

  Future<void> _elegirRango(String rango) async {
    final pendiente = _pendiente;
    if (pendiente == null || pendiente.regimenElegido == null) return;
    await _enviar(
      pendiente.mensajeOriginal,
      regimen: pendiente.regimenElegido,
      rangoIngresos: rango,
      mostrarComoMensajeUsuario: _opcionesRango[rango],
    );
  }

  Future<void> _elegirSugerencia(SugerenciaChatbot sugerencia) async {
    final pendientes = _sugerencias;
    if (pendientes == null) return;
    await _enviar(
      pendientes.mensajeOriginal,
      intencionForzada: sugerencia.intencion,
      mostrarComoMensajeUsuario: sugerencia.etiqueta,
    );
  }

  Future<void> _enviar(
    String mensaje, {
    String? eps,
    String? regimen,
    String? rangoIngresos,
    String? intencionForzada,
    String? mostrarComoMensajeUsuario,
  }) async {
    setState(() {
      _enviando = true;
      _pendiente = null;
      _sugerencias = null;
      if (mostrarComoMensajeUsuario != null) {
        _mensajes.add(_MensajeLocal(texto: mostrarComoMensajeUsuario, esUsuario: true));
      }
    });
    _desplazarAlFinal();

    try {
      final respuesta = await ref.read(chatbotDatasourceProvider).enviarMensaje(
            mensaje,
            eps: eps,
            regimen: regimen,
            rangoIngresos: rangoIngresos,
            intentosSinExitoSeguidos: _fallosSeguidos,
            intencionForzada: intencionForzada,
          );

      setState(() {
        _mensajes.add(_MensajeLocal(texto: respuesta.respuesta, esUsuario: false));
        _fallosSeguidos = respuesta.intencion == 'desconocido' ? _fallosSeguidos + 1 : 0;
        if (respuesta.requiereDatos != null) {
          _pendiente = _FlujoPendiente(tipo: respuesta.requiereDatos!, mensajeOriginal: mensaje);
        } else if (respuesta.sugerencias != null && respuesta.sugerencias!.isNotEmpty) {
          _sugerencias = _SugerenciasPendientes(
            mensajeOriginal: mensaje,
            opciones: respuesta.sugerencias!,
          );
        }
      });
    } catch (err) {
      final texto = err is ApiException
          ? err.message
          : 'No se pudo conectar. Probá de nuevo en un momento.';
      setState(() => _mensajes.add(_MensajeLocal(texto: texto, esUsuario: false)));
    } finally {
      if (mounted) setState(() => _enviando = false);
      _desplazarAlFinal();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fuerza repintar esta pantalla ya montada cuando se togglea modo
    // oscuro/alto contraste desde Perfil (ver AppColors.configurar en
    // main.dart) — sin este watch, Riverpod no sabría que repintar.
    ref.watch(modoOscuroProvider);
    ref.watch(modoAltoContrasteProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'Asistente MediRuta',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.navy),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.navy, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _mensajes.length,
                    itemBuilder: (context, index) => _BurbujaChatbot(mensaje: _mensajes[index]),
                  ),
                ),
                if (_enviando)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (_pendiente?.tipo == 'datos_copago')
                  _OpcionesCopago(
                    pidiendoRango: _pendiente!.regimenElegido != null,
                    deshabilitado: _enviando,
                    onRegimen: _elegirRegimen,
                    onRango: _elegirRango,
                  ),
                if (_sugerencias != null)
                  _SugerenciasChatbot(
                    opciones: _sugerencias!.opciones,
                    deshabilitado: _enviando,
                    onElegir: _elegirSugerencia,
                  ),
                _CampoEnvio(
                  controller: _controller,
                  enviando: _enviando,
                  placeholder: _pendiente?.tipo == 'eps' ? 'Escribí tu EPS…' : 'Escribí tu pregunta…',
                  onEnviar: _enviarTexto,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BurbujaChatbot extends StatelessWidget {
  const _BurbujaChatbot({required this.mensaje});

  final _MensajeLocal mensaje;

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.esUsuario;
    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: esUsuario ? AppColors.teal : AppColors.skyBlue,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(esUsuario ? 16 : 4),
            bottomRight: Radius.circular(esUsuario ? 4 : 16),
          ),
        ),
        child: Text(
          mensaje.texto,
          style: TextStyle(
            color: esUsuario ? AppColors.white : AppColors.navy,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _OpcionesCopago extends StatelessWidget {
  const _OpcionesCopago({
    required this.pidiendoRango,
    required this.deshabilitado,
    required this.onRegimen,
    required this.onRango,
  });

  final bool pidiendoRango;
  final bool deshabilitado;
  final void Function(String regimen) onRegimen;
  final void Function(String rango) onRango;

  @override
  Widget build(BuildContext context) {
    final opciones = pidiendoRango
        ? _opcionesRango.entries.map((e) => (e.key, e.value)).toList()
        : const [('contributivo', 'Contributivo'), ('subsidiado', 'Subsidiado')];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (valor, etiqueta) in opciones)
            OutlinedButton(
              onPressed: deshabilitado
                  ? null
                  : () => pidiendoRango ? onRango(valor) : onRegimen(valor),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: BorderSide(color: AppColors.teal),
              ),
              child: Text(etiqueta),
            ),
        ],
      ),
    );
  }
}

class _SugerenciasChatbot extends StatelessWidget {
  const _SugerenciasChatbot({
    required this.opciones,
    required this.deshabilitado,
    required this.onElegir,
  });

  final List<SugerenciaChatbot> opciones;
  final bool deshabilitado;
  final void Function(SugerenciaChatbot sugerencia) onElegir;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final opcion in opciones)
            OutlinedButton(
              onPressed: deshabilitado ? null : () => onElegir(opcion),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: BorderSide(color: AppColors.teal),
              ),
              child: Text(opcion.etiqueta),
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
    required this.placeholder,
    required this.onEnviar,
  });

  final TextEditingController controller;
  final bool enviando;
  final String placeholder;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !enviando,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onEnviar(),
              decoration: InputDecoration(
                hintText: placeholder,
                filled: true,
                fillColor: AppColors.beige,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: enviando ? null : onEnviar,
            icon: Icon(Icons.send_rounded, color: AppColors.teal),
          ),
        ],
      ),
    );
  }
}
