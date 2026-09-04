import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_order_card.dart';
import '../../../../shared/widgets/app_segmented_tabs.dart';
import '../../../usuarios/presentation/widgets/main_bottom_bar.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.navy, size: 22),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
        ),
        title: const Text(
          'Mis pedidos',
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
                      // Tabs
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.skyBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _TabItem(
                              label: 'Activos',
                              seleccionado: _tab == 0,
                              onTap: () => setState(() => _tab = 0),
                            ),
                            _TabItem(
                              label: 'Historial',
                              seleccionado: _tab == 1,
                              onTap: () => setState(() => _tab = 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (visibles.isEmpty && _error == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            children: [
                              Icon(
                                _tab == 0 ? Icons.inbox_outlined : Icons.history_outlined,
                                size: 64,
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _tab == 0
                                    ? 'No tenés pedidos en curso'
                                    : 'Todavía no hay pedidos en tu historial',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _tab == 0
                                    ? 'Los pedidos que aceptes aparecerán aquí.'
                                    : 'Cuando completes entregas, aparecerán aquí.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      for (final pedido in visibles) ...[
                        _PedidoHistorialCard(
                          pedido: pedido,
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

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.seleccionado,
    required this.onTap,
  });

  final String label;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: seleccionado ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: seleccionado
                ? [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: seleccionado ? AppColors.navy : AppColors.navy.withValues(alpha: 0.5),
                fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PedidoHistorialCard extends StatelessWidget {
  const _PedidoHistorialCard({
    required this.pedido,
  });

  final PedidoHistorial pedido;

  String _getEstadoLabel() {
    switch (pedido.estado) {
      case 'entregado':
        return 'Entregado';
      case 'cancelada':
        return 'Cancelado';
      case 'asignado_en_camino_farmacia':
        return 'En camino a farmacia';
      case 'medicamentos_recogidos':
        return 'Medicamentos recogidos';
      case 'en_camino_entrega':
        return 'En camino a entrega';
      case 'en_sitio':
        return 'En sitio';
      default:
        return pedido.estado;
    }
  }

  Color _getEstadoColor() {
    switch (pedido.estado) {
      case 'entregado':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'asignado_en_camino_farmacia':
        return Colors.orange;
      case 'medicamentos_recogidos':
        return AppColors.teal;
      case 'en_camino_entrega':
        return Colors.blue;
      case 'en_sitio':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getIconoAsset() {
    // Para pedidos entregados o cancelados usamos check.png
    if (pedido.estado == 'entregado' || pedido.estado == 'cancelada') {
      return 'assets/images/check.png';
    }
    // Para pedidos activos (en curso) usamos pedido.png
    return 'assets/images/pedido.png';
  }

  /// Devuelve el tamaño del icono según el tipo de imagen
  double _getIconSize() {
    final esEntregadoOCancelado = pedido.estado == 'entregado' || pedido.estado == 'cancelada';
    // check.png = 45, pedido.png = 64
    return esEntregadoOCancelado ? 45 : 64;
  }

  bool _esEntregadoOCancelado() {
    return pedido.estado == 'entregado' || pedido.estado == 'cancelada';
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = _getIconSize();
    final esHistorial = _esEntregadoOCancelado();
    final borderRadius = esHistorial ? 12.0 : 16.0;
    
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
          // Icono personalizado con imagen - TAMAÑO DINÁMICO
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: _getEstadoColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image.asset(
                _getIconoAsset(),
                width: iconSize,
                height: iconSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  esHistorial
                      ? Icons.check_circle_outline
                      : Icons.local_shipping_outlined,
                  color: _getEstadoColor(),
                  size: iconSize * 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
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
                Text(
                  pedido.direccionEntrega ?? _formatearFecha(pedido.creadoEn),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getEstadoColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getEstadoLabel(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getEstadoColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Fecha
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Colors.grey.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 4),
              Text(
                _formatearFecha(pedido.creadoEn),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
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