import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_status_pill.dart';
import '../../domain/entities/pedido_activo.dart';
import '../providers/solicitud_providers.dart';
import '../widgets/app_tracking_timeline.dart';

/// Detalle de solo lectura de un pedido ya entregado o cancelado, desde
/// el tab "Historial" de "Mis pedidos" del Domiciliario — antes tocar
/// una de esas filas no llevaba a ningún lado. A propósito no muestra
/// medicamentos ni documentos del paciente (cédula/receta): el
/// Domiciliario nunca los ve fuera de su ventana legítima (HU-09), y un
/// pedido ya cerrado ya no aplica.
class PedidoCompletadoScreen extends ConsumerStatefulWidget {
  const PedidoCompletadoScreen({super.key, required this.solicitudId});

  static const routeName = '/pedidos/completado';

  final String solicitudId;

  @override
  ConsumerState<PedidoCompletadoScreen> createState() => _PedidoCompletadoScreenState();
}

class _PedidoCompletadoScreenState extends ConsumerState<PedidoCompletadoScreen> {
  bool _cargando = true;
  PedidoActivo? _pedido;
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
      final pedido = await ref
          .read(obtenerPedidoDomiciliarioUseCaseProvider)
          .execute(widget.solicitudId);
      if (!mounted) return;
      setState(() => _pedido = pedido);
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.navy, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _pedido?.codigoPedido ?? 'Pedido',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.navy,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
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
                      if (_pedido != null) ..._contenido(_pedido!),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  List<Widget> _contenido(PedidoActivo pedido) {
    return [
      Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.skyBlue.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.medication_outlined,
                    color: AppColors.teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pedido.codigoPedido ?? 'Pedido',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                AppStatusPill(estado: pedido.estado),
              ],
            ),
            const SizedBox(height: 12),
            _FilaDireccion(
              icono: Icons.storefront_outlined,
              texto: pedido.direccionFarmacia,
              label: 'Farmacia',
            ),
            const SizedBox(height: 6),
            _FilaDireccion(
              icono: Icons.home_outlined,
              texto: pedido.direccionEntrega,
              label: 'Entrega',
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      if (pedido.estado == 'cancelada')
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.close, color: AppColors.teal, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Este pedido fue cancelado.',
                  style: TextStyle(color: AppColors.navy, fontSize: 14),
                ),
              ),
            ],
          ),
        )
      else
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: AppTrackingTimeline(
            estadoActual: pedido.estado,
            historial: pedido.historial,
          ),
        ),
    ];
  }
}

class _FilaDireccion extends StatelessWidget {
  const _FilaDireccion({
    required this.icono,
    required this.texto,
    required this.label,
  });

  final IconData icono;
  final String? texto;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          child: Icon(icono, color: AppColors.teal, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.navy.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                texto ?? 'Sin registrar',
                style: const TextStyle(color: AppColors.navy, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
