import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_icon_badge.dart';
import '../../../../shared/widgets/app_image_viewer.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../domain/entities/solicitud.dart';
import '../providers/solicitud_providers.dart';
import 'nueva_solicitud_screen.dart';

const _etiquetasEstado = {
  'borrador': 'Borrador',
  'pendiente_revision': 'Pendiente de revisión',
  'cancelada': 'Cancelada',
};

/// G03/G05/G06 — HU-03. Detalle, historial de estados y acciones según
/// el estado actual.
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
        title: const Text('Cancelar solicitud'),
        content: const Text('¿Querés cancelar esta solicitud? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar solicitud'),
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

  @override
  Widget build(BuildContext context) {
    final solicitud = _solicitud;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de solicitud')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: AppIconBadge(icono: Icons.medication_outlined),
                      ),
                      const SizedBox(height: 20),
                      if (_error != null) ...[
                        AppErrorBanner(mensaje: _error!),
                        const SizedBox(height: 16),
                      ],
                      if (solicitud != null) ...[
                        if (solicitud.codigoPedido != null) ...[
                          Text(
                            solicitud.codigoPedido!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          _etiquetasEstado[solicitud.estado] ?? solicitud.estado,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
                        ),
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
                          miniatura: solicitud.recetaUrl,
                          miniaturaEtiqueta: 'Foto de la receta',
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
                          miniatura: solicitud.cedulaUrl,
                          miniaturaEtiqueta: 'Cédula (de tu perfil)',
                        ),
                        const SizedBox(height: 16),
                        _Tarjeta(
                          titulo: 'Historial',
                          filas: {
                            for (final evento in solicitud.historial)
                              (_etiquetasEstado[evento.estado] ?? evento.estado): evento.creadoEn,
                          },
                        ),
                        const SizedBox(height: 24),
                        if (solicitud.estado == 'borrador') ...[
                          AppButton(
                            variante: AppButtonVariante.secondary,
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
                            label: 'Editar',
                          ),
                          const SizedBox(height: 8),
                          AppLoadingButton(
                            label: 'Enviar a revisión',
                            cargando: _procesando,
                            onPressed: _calcularFaltantes(solicitud).isEmpty ? _enviar : null,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (solicitud.estado != 'cancelada')
                          AppLoadingButton(
                            variante: AppButtonVariante.secondary,
                            label: 'Cancelar solicitud',
                            cargando: _procesando,
                            onPressed: _cancelar,
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

/// G05 — mismos requisitos que valida `app.enviar_solicitud` en la API
/// (la cédula no se revisa acá, ya se exigió al crear), incluyendo el
/// chequeo de receta vencida. Se calcula sobre el `Solicitud` ya cargado
/// del detalle, a diferencia del formulario de creación/edición que lo
/// calcula sobre `DatosSolicitud` en progreso — mismo criterio, distinta
/// fuente de datos.
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

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.titulo,
    required this.filas,
    this.miniatura,
    this.miniaturaEtiqueta,
  });

  final String titulo;
  final Map<String, String?> filas;
  final String? miniatura;
  final String? miniaturaEtiqueta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titulo,
            style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          if (miniaturaEtiqueta != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _Miniatura(url: miniatura),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    miniatura == null
                        ? '$miniaturaEtiqueta — no subida'
                        : (miniatura!.split('?').first.toLowerCase().endsWith('.pdf')
                              ? miniaturaEtiqueta!
                              : '$miniaturaEtiqueta — toca para verla'),
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

/// Miniatura 44x44 de un documento: imagen real si es jpg/png, ícono de
/// PDF si corresponde, círculo vacío si todavía no hay nada subido.
/// Mismo patrón que `_Miniatura` de `perfil_screen.dart` (HU-02). Si es
/// una imagen (no PDF, no vacía), tocarla la abre en pantalla completa
/// con zoom — una miniatura de 44px no alcanza para leer una receta.
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
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.teal)),
      );
    }

    return GestureDetector(
      onTap: _esPdf ? null : () => mostrarImagenCompleta(context, url: url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: tamano,
          height: tamano,
          color: AppColors.beige,
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
