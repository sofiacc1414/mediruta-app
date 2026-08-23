import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_icon_badge.dart';
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
      await ref.read(enviarSolicitudUseCaseProvider).execute(widget.solicitudId);
      await _cargar();
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
                        Text(
                          _etiquetasEstado[solicitud.estado] ?? solicitud.estado,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        _Tarjeta(
                          titulo: 'Medicamento',
                          filas: {
                            'Nombre': solicitud.datos.medicamentoNombre,
                            'Concentración/dosis': solicitud.datos.medicamentoConcentracion,
                            'Forma farmacéutica': solicitud.datos.medicamentoFormaFarmaceutica,
                            'Cantidad': solicitud.datos.medicamentoCantidad,
                            'Posología': solicitud.datos.medicamentoPosologia,
                          },
                        ),
                        const SizedBox(height: 16),
                        _Tarjeta(
                          titulo: 'Receta médica',
                          filas: {
                            'Médico': solicitud.datos.recetaMedicoNombre,
                            'Registro médico': solicitud.datos.recetaMedicoRegistro,
                            'IPS': solicitud.datos.recetaIps,
                            'Fecha de expedición': solicitud.datos.recetaFechaExpedicion,
                          },
                        ),
                        const SizedBox(height: 16),
                        _Tarjeta(
                          titulo: 'Entrega',
                          filas: {'Dirección': solicitud.datos.direccionEntrega},
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
                            onPressed: solicitud.datos.calcularFaltantes().isEmpty ? _enviar : null,
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

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.titulo, required this.filas});

  final String titulo;
  final Map<String, String?> filas;

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
