import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../shared/core/network/tracking_socket_service.dart';
import '../../../shared/core/theme/app_colors.dart';
import '../../usuarios/presentation/providers/usuario_providers.dart';
import '../domain/posicion_en_vivo.dart';

/// Seguimiento GPS en vivo del domiciliario — Paciente y Admin lo ven
/// como espectadores pasivos mientras el pedido está en camino. No
/// reinventa ninguna regla de negocio (quién puede verlo, cuándo
/// vence): todo lo decide la API, acá solo se muestra lo que llega.
class SeguimientoMapaScreen extends ConsumerStatefulWidget {
  const SeguimientoMapaScreen({super.key, required this.solicitudId});

  static const routeName = '/seguimiento-mapa';

  final String solicitudId;

  @override
  ConsumerState<SeguimientoMapaScreen> createState() => _SeguimientoMapaScreenState();
}

class _SeguimientoMapaScreenState extends ConsumerState<SeguimientoMapaScreen> {
  // PRD G04 — si no llega ningún ping en 45s, se congela el marcador y
  // se avisa en pantalla en vez de dejarlo ahí sin explicación.
  static const _ventanaSinSenal = Duration(seconds: 45);

  final _socket = TrackingSocketService();
  final _mapController = MapController();
  StreamSubscription<PosicionEnVivo>? _subInicial;
  StreamSubscription<PosicionActualizada>? _subPosicion;
  StreamSubscription<void>? _subFinalizado;
  Timer? _timerSinSenal;

  bool _cargando = true;
  String? _error;
  LatLng? _domiciliario;
  LatLng? _farmacia;
  LatLng? _entrega;
  List<LatLng> _ruta = const [];
  bool _sinSenal = false;
  bool _finalizado = false;

  @override
  void initState() {
    super.initState();
    _subInicial = _socket.posicionInicial.listen(_onPosicionInicial);
    _subPosicion = _socket.posicionNueva.listen(_onPosicionNueva);
    _subFinalizado = _socket.finalizado.listen((_) {
      if (!mounted) return;
      setState(() => _finalizado = true);
    });
    _socket.error.listen((motivo) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = _mensajeError(motivo);
      });
    });
    unawaited(
      _socket.conectarYSuscribir(ref.read(apiClientProvider), widget.solicitudId),
    );
  }

  @override
  void dispose() {
    _subInicial?.cancel();
    _subPosicion?.cancel();
    _subFinalizado?.cancel();
    _timerSinSenal?.cancel();
    _socket.desconectar();
    super.dispose();
  }

  String _mensajeError(String motivo) {
    if (motivo == 'TrackingNoDisponibleError') {
      return 'El seguimiento en vivo no está disponible para este pedido en este momento.';
    }
    if (motivo == 'NoAutorizadoError') {
      return 'No podés ver el seguimiento de este pedido.';
    }
    return 'No se pudo cargar el seguimiento en vivo.';
  }

  void _onPosicionInicial(PosicionEnVivo posicion) {
    if (!mounted) return;
    final domiciliario = posicion.domiciliarioLat != null && posicion.domiciliarioLng != null
        ? LatLng(posicion.domiciliarioLat!, posicion.domiciliarioLng!)
        : null;
    final farmacia = posicion.farmaciaLat != null && posicion.farmaciaLng != null
        ? LatLng(posicion.farmaciaLat!, posicion.farmaciaLng!)
        : null;
    final entrega = posicion.entregaLat != null && posicion.entregaLng != null
        ? LatLng(posicion.entregaLat!, posicion.entregaLng!)
        : null;
    setState(() {
      _cargando = false;
      _domiciliario = domiciliario;
      _farmacia = farmacia;
      _entrega = entrega;
    });
    _resetearTimerSinSenal();
    if (domiciliario != null && entrega != null) {
      unawaited(_pedirRuta(domiciliario, entrega));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _centrarMapa());
  }

  void _onPosicionNueva(PosicionActualizada posicion) {
    if (!mounted) return;
    setState(() {
      _domiciliario = LatLng(posicion.lat, posicion.lng);
      _sinSenal = false;
    });
    _resetearTimerSinSenal();
  }

  void _resetearTimerSinSenal() {
    _timerSinSenal?.cancel();
    _timerSinSenal = Timer(_ventanaSinSenal, () {
      if (!mounted) return;
      setState(() => _sinSenal = true);
    });
  }

  void _centrarMapa() {
    final d = _domiciliario;
    if (d == null) return;
    try {
      _mapController.move(d, 15);
    } catch (_) {
      // El mapa puede no estar montado todavía en el primer frame.
    }
  }

  /// PRD 5.1 — trazado inicial de la ruta vial vía OSRM (servidor
  /// público demo, gratis, sin SLA — igual que Nominatim: si falla, el
  /// mapa se queda sin la polyline pero los marcadores igual sirven).
  Future<void> _pedirRuta(LatLng desde, LatLng hasta) async {
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${desde.longitude},${desde.latitude};${hasta.longitude},${hasta.latitude}'
        '?geometries=geojson&overview=full',
      );
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 8));
      if (respuesta.statusCode != 200) return;
      final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;
      final rutas = cuerpo['routes'] as List<dynamic>?;
      if (rutas == null || rutas.isEmpty) return;
      final coords = (rutas.first['geometry']['coordinates'] as List<dynamic>)
          .map((c) => LatLng((c as List)[1] as double, c[0] as double))
          .toList();
      if (!mounted) return;
      setState(() => _ruta = coords);
    } catch (_) {
      // Best-effort — sin ruta trazada, el mapa sigue mostrando los
      // marcadores igual.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Seguimiento en vivo',
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
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: _AvisoMapa(icono: Icons.info_outline, texto: _error!),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _domiciliario ?? _farmacia ?? _entrega ?? const LatLng(6.2442, -75.5812),
                        initialZoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.mediruta.app',
                        ),
                        if (_ruta.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(points: _ruta, color: AppColors.teal, strokeWidth: 4),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            if (_farmacia != null)
                              Marker(
                                point: _farmacia!,
                                width: 36,
                                height: 36,
                                child: const Icon(Icons.storefront_rounded, color: AppColors.navy, size: 30),
                              ),
                            if (_entrega != null)
                              Marker(
                                point: _entrega!,
                                width: 36,
                                height: 36,
                                child: const Icon(Icons.home_rounded, color: AppColors.navy, size: 30),
                              ),
                            if (_domiciliario != null)
                              Marker(
                                point: _domiciliario!,
                                width: 44,
                                height: 44,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.85, end: 1),
                                  duration: const Duration(milliseconds: 400),
                                  builder: (context, escala, child) => Transform.scale(scale: escala, child: child),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.teal,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.two_wheeler_rounded,
                                      color: AppColors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (_finalizado)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: _AvisoMapa(
                          icono: Icons.flag_rounded,
                          texto: 'El seguimiento terminó — el pedido ya no está en camino.',
                        ),
                      )
                    else if (_sinSenal)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: _AvisoMapa(
                          icono: Icons.gps_off_rounded,
                          texto: 'Ubicación temporalmente no disponible.',
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _AvisoMapa extends StatelessWidget {
  const _AvisoMapa({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.skyBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navy, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icono, color: AppColors.navy, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: AppColors.navy, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
