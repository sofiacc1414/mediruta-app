import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Una sugerencia de dirección real mientras se escribe — ver
/// `SugerenciasDireccion`. Forma mínima, feature-agnóstica: cada
/// feature (perfil, pedidos) adapta su propio `CandidatoDireccion`/
/// `CandidatoDireccionPerfil` a esto al armar `buscar`.
class SugerenciaDireccion {
  const SugerenciaDireccion({
    required this.lat,
    required this.lng,
    required this.direccionResuelta,
    required this.precisa,
  });

  final double lat;
  final double lng;
  final String direccionResuelta;
  /// Bug real reportado: elegir una sugerencia y volver a
  /// geocodificarla (un segundo viaje de red, solo para "confirmarla")
  /// a veces fallaba aunque la primera consulta sí hubiera funcionado.
  /// Se manda esta bandera para que quien la reciba pueda confiar en
  /// el resultado directamente, sin un segundo request — ya viene de
  /// un geocode exitoso.
  final bool precisa;
}

/// Ronda 13 — bug real reportado: había que terminar de escribir y
/// salir del campo para enterarse de si una dirección existía (ej.
/// "universidad de medellin" no daba ninguna pista hasta perder el
/// foco). Este widget NO tiene su propio `TextField` — se coloca
/// debajo de un campo ya existente (mismo patrón que
/// `MensajeConfirmacionDireccion`/`MensajeConfirmacionDireccionPerfil`)
/// y escucha su `controller`/`focusNode` para mostrar una lista de
/// sugerencias en vivo, con debounce, mientras el usuario escribe.
/// Tocar una sugerencia completa el campo con la dirección real.
class SugerenciasDireccion extends StatefulWidget {
  const SugerenciasDireccion({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.buscar,
    this.onSeleccionar,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Future<List<SugerenciaDireccion>> Function(String texto) buscar;
  final ValueChanged<SugerenciaDireccion>? onSeleccionar;

  @override
  State<SugerenciasDireccion> createState() => _SugerenciasDireccionState();
}

class _SugerenciasDireccionState extends State<SugerenciasDireccion> {
  // Nominatim tiene un límite de 1 request/segundo COMPARTIDO entre
  // todos los usuarios (ver NominatimGeocodificacionAdapter) — este
  // debounce, más el mínimo de caracteres, evita que cada tecla
  // dispare un request (mismo problema, mismo criterio, que ya se
  // corrigió para el estimado de precio en vivo).
  static const _debounceDelay = Duration(milliseconds: 600);
  static const _minimoCaracteres = 4;

  Timer? _debounce;
  List<SugerenciaDireccion> _sugerencias = const [];
  bool _ignorarProximoCambio = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextoCambio);
    widget.focusNode.addListener(_onFocoCambio);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextoCambio);
    widget.focusNode.removeListener(_onFocoCambio);
    super.dispose();
  }

  void _onFocoCambio() {
    if (widget.focusNode.hasFocus) return;
    // Delay antes de ocultar: si el foco se perdió porque el usuario
    // tocó una sugerencia, ese toque todavía no terminó de procesarse
    // — ocultar de una lo haría desaparecer antes de que el tap
    // llegue a registrarse.
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && !widget.focusNode.hasFocus && _sugerencias.isNotEmpty) {
        setState(() => _sugerencias = const []);
      }
    });
  }

  void _onTextoCambio() {
    if (_ignorarProximoCambio) {
      _ignorarProximoCambio = false;
      return;
    }
    _debounce?.cancel();
    final texto = widget.controller.text.trim();
    if (texto.length < _minimoCaracteres) {
      if (_sugerencias.isNotEmpty) setState(() => _sugerencias = const []);
      return;
    }
    _debounce = Timer(_debounceDelay, () => _buscar(texto));
  }

  Future<void> _buscar(String texto) async {
    try {
      final resultado = await widget.buscar(texto);
      if (!mounted) return;
      // El usuario pudo haber seguido escribiendo (o borrado todo)
      // mientras este request estaba en vuelo.
      if (widget.controller.text.trim() != texto) return;
      setState(() => _sugerencias = resultado);
    } catch (_) {
      // Best effort — una falla acá no debe interrumpir seguir
      // escribiendo la dirección a mano.
    }
  }

  void _seleccionar(SugerenciaDireccion sugerencia) {
    _ignorarProximoCambio = true;
    widget.controller.text = sugerencia.direccionResuelta;
    setState(() => _sugerencias = const []);
    widget.onSeleccionar?.call(sugerencia);
  }

  @override
  Widget build(BuildContext context) {
    if (_sugerencias.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final sugerencia in _sugerencias)
            InkWell(
              onTap: () => _seleccionar(sugerencia),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.navy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sugerencia.direccionResuelta,
                        style: const TextStyle(fontSize: 13, color: AppColors.navy),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
