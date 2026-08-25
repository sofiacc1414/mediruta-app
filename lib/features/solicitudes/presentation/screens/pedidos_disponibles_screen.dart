import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_order_card.dart';
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
  bool _cargando = true;
  List<PedidoDisponible>? _pedidos;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
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
      appBar: AppBar(title: const Text('Pedidos disponibles')),
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
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Text(
                            'No hay pedidos cerca ahora mismo. Si no estás '
                            '"Disponible" en Inicio, activalo para empezar a '
                            'recibirlos.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.teal),
                          ),
                        ),
                      for (final pedido in _pedidos ?? []) ...[
                        AppOrderCard(
                          titulo: pedido.codigoPedido ?? 'Pedido',
                          subtitulo:
                              '${pedido.distanciaKm.toStringAsFixed(1)} km · '
                              '${pedido.direccionFarmacia ?? 'Farmacia sin dirección'}',
                          trailing: _BotonAceptarPequeno(onTap: () => _aceptar(pedido)),
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

class _BotonAceptarPequeno extends StatelessWidget {
  const _BotonAceptarPequeno({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: const StadiumBorder(),
      ),
      child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
