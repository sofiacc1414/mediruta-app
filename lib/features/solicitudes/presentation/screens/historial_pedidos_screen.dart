import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_order_card.dart';
import '../../../../shared/widgets/app_segmented_tabs.dart';
import '../../domain/entities/pedido_historial.dart';
import '../providers/solicitud_providers.dart';

const _estadosHistorial = {'entregado', 'cancelada'};

/// "Mis pedidos" del Domiciliario — todos los que aceptó alguna vez,
/// mismo lenguaje visual que `MisSolicitudesScreen` del Paciente
/// (AppOrderCard + tabs Activas/Historial), pero de solo lectura: acá
/// no hay una pantalla de detalle propia del Domiciliario más allá de
/// "Mi pedido activo" (que ya se ve desde Home mientras está en curso).
class HistorialPedidosScreen extends ConsumerStatefulWidget {
  const HistorialPedidosScreen({super.key});

  static const routeName = '/pedidos/mis-pedidos';

  @override
  ConsumerState<HistorialPedidosScreen> createState() => _HistorialPedidosScreenState();
}

class _HistorialPedidosScreenState extends ConsumerState<HistorialPedidosScreen> {
  bool _cargando = true;
  List<PedidoHistorial>? _pedidos;
  String? _error;
  int _tab = 0;

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
      final pedidos = await ref.read(listarHistorialPedidosUseCaseProvider).execute();
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

  @override
  Widget build(BuildContext context) {
    final todos = _pedidos ?? const <PedidoHistorial>[];
    final esHistorial = _tab == 1;
    final visibles =
        todos.where((p) => _estadosHistorial.contains(p.estado) == esHistorial).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
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
                      AppSegmentedTabs(
                        opciones: const ['Activos', 'Historial'],
                        seleccionado: _tab,
                        onSeleccionar: (i) => setState(() => _tab = i),
                      ),
                      const SizedBox(height: 16),
                      if (visibles.isEmpty && _error == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            _tab == 0
                                ? 'No tenés pedidos en curso ahora mismo.'
                                : 'Todavía no hay pedidos en tu historial.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.teal),
                          ),
                        ),
                      for (final pedido in visibles) ...[
                        AppOrderCard(
                          titulo: pedido.codigoPedido ?? 'Pedido',
                          subtitulo: pedido.direccionEntrega ?? _formatearFecha(pedido.creadoEn),
                          estado: pedido.estado,
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

String _formatearFecha(String iso) {
  final fecha = DateTime.tryParse(iso)?.toLocal();
  if (fecha == null) return iso;
  final dia = fecha.day.toString().padLeft(2, '0');
  const meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  return '$dia ${meses[fecha.month - 1]} ${fecha.year}';
}
