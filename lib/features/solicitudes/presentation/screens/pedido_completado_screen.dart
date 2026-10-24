import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_status_pill.dart';
import '../../domain/entities/pedido_activo.dart';
import '../providers/solicitud_providers.dart';
import '../widgets/app_tracking_timeline.dart';
import '../../../../shared/core/theme/modo_alto_contraste_provider.dart';
import '../../../../shared/core/theme/modo_oscuro_provider.dart';

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
    // Fuerza repintar esta pantalla ya montada cuando se togglea modo
    // oscuro/alto contraste desde Perfil (ver AppColors.configurar en
    // main.dart) — sin este watch, Riverpod no sabría que repintar.
    ref.watch(modoOscuroProvider);
    ref.watch(modoAltoContrasteProvider);
    return Scaffold(
      backgroundColor: AppColors.fondoPagina,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.navy, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _pedido?.codigoPedido ?? 'Pedido',
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
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
                  child: Icon(
                    Icons.medication_outlined,
                    color: AppColors.teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pedido.codigoPedido ?? 'Pedido',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                Flexible(child: AppStatusPill(estado: pedido.estado)),
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
            color: AppColors.skyBlue.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
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
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
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
                style: TextStyle(color: AppColors.navy, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
