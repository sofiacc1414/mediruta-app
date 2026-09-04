import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../usuarios/presentation/widgets/main_bottom_bar.dart';
import '../../domain/entities/pedido_disponible.dart';
import '../providers/solicitud_providers.dart';
import 'mi_pedido_activo_screen.dart';

/// HU-09 — pool de pedidos del Domiciliario, ordenado por distancia real
/// (ya la trae calculada `listar_pedidos_disponibles`). Vacío tanto si no
/// hay pedidos cerca como si el Domiciliario no está "Disponible" — sin
/// una señal aparte de la API para distinguirlos, se muestra un mensaje
/// que cubre ambos casos.
class PedidosDisponiblesScreen extends ConsumerStatefulWidget {
  const PedidosDisponiblesScreen({super.key});

  static const routeName = '/pedidos/disponibles';

  @override
  ConsumerState<PedidosDisponiblesScreen> createState() =>
      _PedidosDisponiblesScreenState();
}

class _PedidosDisponiblesScreenState extends ConsumerState<PedidosDisponiblesScreen> {
  // Sin WebSocket/Supabase Realtime en la App todavía (alcance acordado:
  // "sin mapa visual, 100% open source pero simple") — un pedido nuevo
  // no tiene forma de avisar solo. Poll cada 15s mientras la pantalla
  // está abierta es la forma más simple de que el pool se actualice sin
  // que el Domiciliario tenga que salir y volver a entrar.
  static const _intervaloPoll = Duration(seconds: 15);

  bool _cargando = true;
  List<PedidoDisponible>? _pedidos;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargar();
    _timer = Timer.periodic(_intervaloPoll, (_) => _cargarSilencioso());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final pedidos = await ref.read(listarPedidosDisponiblesUseCaseProvider).execute();
      if (!mounted) return;
      setState(() => _pedidos = pedidos);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Refresco del poll automático: solo actualiza la lista si sale bien
  /// — nunca toca `_cargando` (no tapa la lista con el spinner de
  /// pantalla completa) ni `_error` (un hiccup de red pasajero cada 15s
  /// no debería interrumpir lo que ya se ve; "pull to refresh" sigue
  /// disponible para un chequeo explícito).
  Future<void> _cargarSilencioso() async {
    try {
      final pedidos = await ref.read(listarPedidosDisponiblesUseCaseProvider).execute();
      if (!mounted) return;
      setState(() => _pedidos = pedidos);
    } on ApiException {
      // silencioso a propósito, ver doc del método
    } on ApiSinConexionException {
      // silencioso a propósito, ver doc del método
    }
  }

  Future<void> _aceptar(PedidoDisponible pedido) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceptar pedido'),
        content: Text(
          '¿Aceptás el pedido ${pedido.codigoPedido ?? ''} y salís hacia '
          '${pedido.direccionFarmacia ?? 'la farmacia'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ahora no'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    try {
      await ref.read(aceptarPedidoUseCaseProvider).execute(pedido.id);
      if (!mounted) return;
      await Navigator.of(context).pushReplacementNamed(MiPedidoActivoScreen.routeName);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.navy, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pedidos disponibles',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.navy,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      bottomNavigationBar: const MainBottomBar(),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_error != null) ...[
                        AppErrorBanner(mensaje: _error!),
                        const SizedBox(height: 16),
                      ],
                      if ((_pedidos?.isEmpty ?? false) && _error == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay pedidos disponibles',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Activa "Disponible" en tu perfil para empezar a recibir pedidos cerca tuyo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      for (final pedido in _pedidos ?? []) ...[
                        _PedidoDisponibleCard(
                          pedido: pedido,
                          onAceptar: () => _aceptar(pedido),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// ==================== WIDGETS DE DISEÑO ====================

class _PedidoDisponibleCard extends StatelessWidget {
  const _PedidoDisponibleCard({
    required this.pedido,
    required this.onAceptar,
  });

  final PedidoDisponible pedido;
  final VoidCallback onAceptar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono - Imagen de fórmula
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.skyBlue.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/formula.png',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.skyBlue.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication_outlined,
                    color: AppColors.teal,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pedido.codigoPedido ?? 'Pedido',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pedido.direccionFarmacia ?? 'Farmacia sin dirección',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.withValues(alpha: 0.7),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${pedido.distanciaKm.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.attach_money_outlined,
                      size: 14,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '\$0', // Temporal: recompensa no disponible
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Botón Aceptar
          Container(
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextButton(
              onPressed: onAceptar,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: const StadiumBorder(),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Aceptar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}