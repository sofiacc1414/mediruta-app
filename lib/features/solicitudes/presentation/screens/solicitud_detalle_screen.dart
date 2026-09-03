import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_image_viewer.dart';
import '../../../../shared/widgets/app_status_pill.dart';
import '../../../usuarios/presentation/widgets/main_bottom_bar.dart';
import '../../domain/entities/solicitud.dart';
import '../providers/solicitud_providers.dart';
import '../widgets/app_tracking_timeline.dart';
import 'nueva_solicitud_screen.dart';

/// G03/G05/G06 — HU-03, con el tracking de HU-07/HU-09.
class SolicitudDetalleScreen extends ConsumerStatefulWidget {
  const SolicitudDetalleScreen({super.key, required this.solicitudId});

  static const routeName = '/solicitudes/detalle';

  final String solicitudId;

  @override
  ConsumerState<SolicitudDetalleScreen> createState() => _SolicitudDetalleScreenState();
}

class _SolicitudDetalleScreenState extends ConsumerState<SolicitudDetalleScreen> {
  bool _cargando = true;
  bool _procesando = false;
  Solicitud? _solicitud;
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
      final solicitud = await ref
          .read(obtenerSolicitudUseCaseProvider)
          .execute(widget.solicitudId);
      if (!mounted) return;
      setState(() => _solicitud = solicitud);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _enviar() async {
    setState(() {
      _procesando = true;
      _error = null;
    });
    try {
      final codigoPedido = await ref
          .read(enviarSolicitudUseCaseProvider)
          .execute(widget.solicitudId);
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Pedido enviado! Tu código es $codigoPedido.')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _cancelar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancelar solicitud', style: TextStyle(color: AppColors.navy)),
        content: const Text('¿Querés cancelar esta solicitud? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver', style: TextStyle(color: AppColors.navy)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar solicitud', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    setState(() {
      _procesando = true;
      _error = null;
    });
    try {
      await ref.read(cancelarSolicitudUseCaseProvider).execute(widget.solicitudId);
      await _cargar();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _reportarNovedad() async {
    final controller = TextEditingController();
    final detalle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reportar novedad', style: TextStyle(color: AppColors.navy)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Contanos qué pasó',
            hintText: 'Ej.: el domiciliario no contesta',
            labelStyle: const TextStyle(color: AppColors.teal),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.teal, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.navy)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Reportar', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
    if (detalle == null || detalle.isEmpty || !mounted) return;

    setState(() {
      _procesando = true;
      _error = null;
    });
    try {
      await ref
          .read(reportarNovedadPacienteUseCaseProvider)
          .execute(widget.solicitudId, detalle);
      await _cargar();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _copiarCodigoEntrega(String codigo) async {
    await Clipboard.setData(ClipboardData(text: codigo));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Código copiado.')));
  }

  @override
  Widget build(BuildContext context) {
    final solicitud = _solicitud;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Detalle de solicitud',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.navy,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.navy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const MainBottomBar(),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) ...[
                        AppErrorBanner(mensaje: _error!),
                        const SizedBox(height: 16),
                      ],
                      if (solicitud != null) ...[
                        // ====== CÓDIGO + ESTADO ======
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  solicitud.codigoPedido ?? 'Borrador de solicitud',
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              AppStatusPill(estado: solicitud.estado),
                            ],
                          ),
                        ),
                        if (solicitud.novedadAbierta != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, color: Colors.red),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Hay una novedad sobre tu pedido: ${solicitud.novedadAbierta!.detalle}',
                                    style: const TextStyle(color: AppColors.navy),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (solicitud.codigoEntrega != null) ...[
                          const SizedBox(height: 16),
                          // ====== CAJÓN DEL CÓDIGO DE ENTREGA (AZUL CLARO #DBEAFE) ======
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE), // Azul claro
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Código de entrega — dáselo al domiciliario',
                                  style: TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        solicitud.codigoEntrega!,
                                        style: const TextStyle(
                                          color: AppColors.navy,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 4,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy_outlined, color: AppColors.navy),
                                      onPressed: () => _copiarCodigoEntrega(solicitud.codigoEntrega!),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (solicitud.codigoPedido != null && solicitud.estado != 'cancelada') ...[
                          const SizedBox(height: 24),
                          AppTrackingTimeline(
                            estadoActual: solicitud.estado,
                            historial: solicitud.historial,
                          ),
                        ],
                        for (var i = 0; i < solicitud.medicamentos.length; i++) ...[
                          const SizedBox(height: 16),
                          _Tarjeta(
                            titulo: 'Medicamento ${i + 1}',
                            filas: {
                              'Nombre': solicitud.medicamentos[i].nombre,
                              'Concentración/dosis': solicitud.medicamentos[i].concentracion,
                              'Forma farmacéutica': solicitud.medicamentos[i].formaFarmaceutica,
                              'Cantidad': solicitud.medicamentos[i].cantidad,
                              'Posología': solicitud.medicamentos[i].posologia,
                            },
                          ),
                        ],
                        if (solicitud.medicamentos.isEmpty) ...[
                          const SizedBox(height: 16),
                          const _Tarjeta(titulo: 'Medicamentos', filas: {'Ninguno cargado': null}),
                        ],
                        const SizedBox(height: 16),
                        _Tarjeta(
                          titulo: 'Receta médica',
                          filas: {'Fecha de vencimiento': solicitud.recetaFechaVencimiento},
                          miniaturas: {'Foto de la receta': solicitud.recetaUrl},
                        ),
                        const SizedBox(height: 16),
                        _Tarjeta(
                          titulo: 'Farmacia',
                          filas: {'Dirección de la farmacia': solicitud.direccionFarmacia},
                        ),
                        const SizedBox(height: 16),
                        _Tarjeta(
                          titulo: 'Identidad y entrega',
                          filas: {'Dirección de entrega': solicitud.direccionEntrega},
                          miniaturas: {
                            'Cédula (frente, de tu perfil)': solicitud.cedulaFrenteUrl,
                            'Cédula (reverso, de tu perfil)': solicitud.cedulaReversoUrl,
                          },
                        ),
                        const SizedBox(height: 24),

                        // ====== BOTONES ESTILO PÍLDORA CON BORDE GRIS ======
                        if (solicitud.estado == 'borrador') ...[
                          _BotonGrisClaro(
                            onPressed: _procesando
                                ? null
                                : () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => NuevaSolicitudScreen(
                                          solicitudId: solicitud.id,
                                        ),
                                      ),
                                    );
                                    _cargar();
                                  },
                            etiqueta: 'Editar',
                          ),
                          const SizedBox(height: 8),
                          // ✅ ELIMINADO: "Enviar a revisión" ya no se muestra aquí
                        ],

                        if (solicitud.estado != 'cancelada')
                          _BotonGrisClaro(
                            onPressed: _procesando ? null : _cancelar,
                            etiqueta: 'Cancelar solicitud',
                            cargando: _procesando,
                          ),

                        if (solicitud.estado != 'cancelada' &&
                            solicitud.estado != 'entregado' &&
                            solicitud.novedadAbierta == null) ...[
                          const SizedBox(height: 8),
                          _BotonGrisClaro(
                            onPressed: _procesando ? null : _reportarNovedad,
                            etiqueta: 'Reportar novedad',
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

List<String> _calcularFaltantes(Solicitud solicitud) {
  final medicamentosNoVacios = solicitud.medicamentos.where((m) => !m.estaVacio).toList();
  final faltantes = <String>[];

  if (medicamentosNoVacios.isEmpty) {
    faltantes.add('Al menos un medicamento');
  } else if (medicamentosNoVacios.any((m) => !m.estaCompleto)) {
    faltantes.add('Completar todos los campos de cada medicamento');
  }
  if (solicitud.recetaUrl == null) {
    faltantes.add('Foto de la receta');
  }
  final fechaVencimiento = solicitud.recetaFechaVencimiento;
  if (fechaVencimiento == null || fechaVencimiento.trim().isEmpty) {
    faltantes.add('Fecha de vencimiento de la receta');
  } else {
    final parseada = DateTime.tryParse(fechaVencimiento);
    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    if (parseada != null && parseada.isBefore(hoySinHora)) {
      faltantes.add('La receta está vencida — sube una foto de una receta vigente');
    }
  }
  if (solicitud.direccionFarmacia == null || solicitud.direccionFarmacia!.trim().isEmpty) {
    faltantes.add('Dirección de la farmacia');
  }
  if (solicitud.direccionEntrega == null || solicitud.direccionEntrega!.trim().isEmpty) {
    faltantes.add('Dirección de entrega');
  }
  return faltantes;
}

// ==================== WIDGETS VISUALES INTERNOS ====================

/// Botón con fondo blanco y borde delgado gris claro (estilo píldora)
class _BotonGrisClaro extends StatelessWidget {
  const _BotonGrisClaro({
    required this.onPressed,
    required this.etiqueta,
    this.cargando = false,
  });

  final VoidCallback? onPressed;
  final String etiqueta;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: cargando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF7F8FA),
          foregroundColor: AppColors.navy,
          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.1),
          disabledForegroundColor: Colors.grey,
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: cargando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
              )
            : Text(
                etiqueta,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

/// Tarjeta compacta para medicamentos (con imagen aún más grande a la izquierda)
class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.titulo,
    required this.filas,
    this.miniaturas = const {},
  });

  final String titulo;
  final Map<String, String?> filas;
  final Map<String, String?> miniaturas;

  @override
  Widget build(BuildContext context) {
    final esMedicamento = titulo.startsWith('Medicamento');

    if (esMedicamento) {
      final filasVisibles = filas.entries
          .where((entrada) => entrada.value != null && entrada.value!.trim().isNotEmpty)
          .toList();

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                color: AppColors.skyBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/pastillera.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.medication_outlined,
                    color: AppColors.navy,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  for (final entrada in filasVisibles)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${entrada.key}: ',
                              style: const TextStyle(
                                color: AppColors.teal,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            TextSpan(
                              text: entrada.value ?? '—',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titulo,
            style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          for (final entrada in miniaturas.entries) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _Miniatura(url: entrada.value),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entrada.value == null
                        ? '${entrada.key} — no subida'
                        : (entrada.value!.split('?').first.toLowerCase().endsWith('.pdf')
                              ? entrada.key
                              : '${entrada.key} — toca para verla'),
                    style: const TextStyle(color: AppColors.navy),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          for (final entrada in filas.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${entrada.key}: ',
                      style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: entrada.value ?? '—',
                      style: const TextStyle(color: AppColors.navy),
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

/// Miniatura 44x44 con borde gris claro
class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.url});

  final String? url;

  bool get _esPdf => url != null && url!.split('?').first.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    const tamano = 44.0;

    if (url == null) {
      return Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 2),
        ),
        child: const Icon(Icons.add, color: AppColors.teal, size: 16),
      );
    }

    return GestureDetector(
      onTap: _esPdf ? null : () => mostrarImagenCompleta(context, url: url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: tamano,
          height: tamano,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: _esPdf
              ? const Icon(Icons.picture_as_pdf_outlined, color: AppColors.navy, size: 22)
              : Image.network(
                  url!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported_outlined, color: AppColors.navy, size: 20),
                ),
        ),
      ),
    );
  }
}