import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_image_viewer.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../../usuarios/presentation/widgets/main_bottom_bar.dart';
import '../../domain/entities/documentos_paciente_para_recoger.dart';
import '../../domain/entities/pedido_activo.dart';
import '../providers/solicitud_providers.dart';
import '../widgets/app_tracking_timeline.dart';

/// HU-09/HU-07 — el pedido que el Domiciliario tiene en curso: mismo
/// `AppTrackingTimeline` que ve el Paciente, con el botón de acción del
/// paso actual embebido junto al punto en curso, y "Reportar novedad"
/// disponible en cualquier paso.
class MiPedidoActivoScreen extends ConsumerStatefulWidget {
  const MiPedidoActivoScreen({super.key});

  static const routeName = '/pedidos/mi-activo';

  @override
  ConsumerState<MiPedidoActivoScreen> createState() => _MiPedidoActivoScreenState();
}

class _MiPedidoActivoScreenState extends ConsumerState<MiPedidoActivoScreen> {
  bool _cargando = true;
  bool _procesando = false;
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
      final pedido = await ref.read(obtenerPedidoActivoUseCaseProvider).execute();
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

  Future<void> _ejecutarPaso(Future<void> Function(String solicitudId) accion) async {
    final pedido = _pedido;
    if (pedido == null) return;
    setState(() {
      _procesando = true;
      _error = null;
    });
    try {
      await accion(pedido.id);
      await _cargar();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _marcarRecogido() => _ejecutarPaso(
        (id) => ref.read(marcarMedicamentosRecogidosUseCaseProvider).execute(id),
      );

  Future<void> _iniciarEntrega() =>
      _ejecutarPaso((id) => ref.read(iniciarEntregaUseCaseProvider).execute(id));

  Future<void> _marcarEnSitio() =>
      _ejecutarPaso((id) => ref.read(marcarEnSitioUseCaseProvider).execute(id));

  Future<void> _entregar() async {
    final pedido = _pedido;
    if (pedido == null) return;
    final controller = TextEditingController();
    String? errorDialogo;

    final codigo = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialogo) => AlertDialog(
          title: const Text('Confirmar entrega'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pedile al paciente el código de 6 caracteres.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Código de entrega',
                  errorText: errorDialogo,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  setStateDialogo(() => errorDialogo = 'Ingresá el código.');
                  return;
                }
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
    if (codigo == null || !mounted) return;

    await _ejecutarPaso(
      (id) => ref.read(entregarPedidoUseCaseProvider).execute(id, codigo),
    );
  }

  Future<void> _reportarNovedad() async {
    final controller = TextEditingController();
    final detalle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar novedad'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Contanos qué pasó',
            hintText: 'Ej.: el paciente no contesta',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
    if (detalle == null || detalle.isEmpty || !mounted) return;

    await _ejecutarPaso(
      (id) => ref.read(reportarNovedadUseCaseProvider).execute(id, detalle),
    );
  }

  /// HU-07/HU-09 — la cédula del Paciente solo es visible acá, en el
  /// único momento en que hay un motivo legítimo para verla: yendo a
  /// reclamar el medicamento a su nombre. El botón que la abre solo
  /// aparece en `asignado_en_camino_farmacia` (ver `build`); si por
  /// timing el pedido ya avanzó de paso cuando se toca, la API la
  /// niega igual (404) y acá se muestra ese error en vez de la cédula.
  Future<void> _verDocumentosPaciente() async {
    final pedido = _pedido;
    if (pedido == null) return;

    DocumentosPacienteParaRecoger? documentos;
    String? error;
    try {
      documentos = await ref
          .read(obtenerDocumentosPacienteParaRecogerUseCaseProvider)
          .execute(pedido.id);
    } on ApiException catch (e) {
      error = e.message;
    } on ApiSinConexionException catch (e) {
      error = e.toString();
    }
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _HojaDocumentosPaciente(
        documentos: documentos,
        error: error,
      ),
    );
  }

  Widget? _accionPara(String estado) {
    if (_procesando) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return switch (estado) {
      'asignado_en_camino_farmacia' => _BotonPaso(
          label: 'Medicamentos recogidos',
          onPressed: _marcarRecogido,
        ),
      'medicamentos_recogidos' => _BotonPaso(
          label: 'Salir hacia el paciente',
          onPressed: _iniciarEntrega,
        ),
      'en_camino_entrega' => _BotonPaso(label: 'Marcar en sitio', onPressed: _marcarEnSitio),
      'en_sitio' => _BotonPaso(label: 'Confirmar entrega', onPressed: _entregar),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final pedido = _pedido;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi pedido activo')),
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
                      if (pedido == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Text(
                            'No tenés ningún pedido en curso ahora mismo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.teal),
                          ),
                        )
                      else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.navy.withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pedido.codigoPedido ?? 'Pedido',
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _FilaDireccion(
                                icono: Icons.storefront_outlined,
                                texto: pedido.direccionFarmacia,
                              ),
                              const SizedBox(height: 4),
                              _FilaDireccion(
                                icono: Icons.home_outlined,
                                texto: pedido.direccionEntrega,
                              ),
                            ],
                          ),
                        ),
                        if (pedido.novedadPropiaAbierta != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.beige,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, color: AppColors.navy),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Novedad reportada: ${pedido.novedadPropiaAbierta!.detalle}\n'
                                    'Un administrador la va a revisar.',
                                    style: const TextStyle(color: AppColors.navy),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (pedido.estado == 'asignado_en_camino_farmacia') ...[
                          const SizedBox(height: 16),
                          AppButton(
                            variante: AppButtonVariante.secondary,
                            label: 'Ver documentos del paciente',
                            onPressed: _verDocumentosPaciente,
                          ),
                        ],
                        const SizedBox(height: 24),
                        AppTrackingTimeline(
                          estadoActual: pedido.estado,
                          historial: pedido.historial,
                          accionPasoActual: _accionPara(pedido.estado),
                        ),
                        const SizedBox(height: 24),
                        if (pedido.novedadPropiaAbierta == null)
                          AppButton(
                            variante: AppButtonVariante.secondary,
                            label: 'Reportar novedad',
                            onPressed: _procesando ? null : _reportarNovedad,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _FilaDireccion extends StatelessWidget {
  const _FilaDireccion({required this.icono, required this.texto});

  final IconData icono;
  final String? texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: AppColors.teal),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto ?? 'Sin dirección',
            style: const TextStyle(color: AppColors.teal, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

/// Contenido del bottom sheet de "Ver documentos del paciente" — la
/// cédula (ambos lados) para mostrarle al personal de la farmacia. Si
/// la API la negó (fuera de la ventana permitida, o error de red) se
/// muestra el error en vez de las imágenes.
class _HojaDocumentosPaciente extends StatelessWidget {
  const _HojaDocumentosPaciente({required this.documentos, required this.error});

  final DocumentosPacienteParaRecoger? documentos;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.skyBlue,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cédula del paciente',
              style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mostrala en la farmacia para retirar el medicamento a su nombre.',
              style: TextStyle(color: AppColors.teal, fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (error != null)
              AppErrorBanner(mensaje: error!)
            else ...[
              _FotoDocumento(label: 'Frente', url: documentos?.cedulaFrenteUrl),
              const SizedBox(height: 16),
              _FotoDocumento(label: 'Reverso', url: documentos?.cedulaReversoUrl),
            ],
          ],
        ),
      ),
    );
  }
}

class _FotoDocumento extends StatelessWidget {
  const _FotoDocumento({required this.label, required this.url});

  final String label;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: url == null ? null : () => mostrarImagenCompleta(context, url: url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 160,
              color: AppColors.beige,
              child: url == null
                  ? const Center(
                      child: Text('No disponible', style: TextStyle(color: AppColors.teal)),
                    )
                  : Image.network(
                      url!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.image_not_supported_outlined, color: AppColors.navy),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BotonPaso extends StatelessWidget {
  const _BotonPaso({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppLoadingButton(label: label, cargando: false, onPressed: onPressed),
    );
  }
}
