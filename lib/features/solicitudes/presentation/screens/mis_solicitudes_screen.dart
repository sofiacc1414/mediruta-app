import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_order_card.dart';
import '../../../../shared/widgets/app_segmented_tabs.dart';
import '../../../usuarios/presentation/providers/perfil_providers.dart';
import '../../../usuarios/presentation/screens/perfil_screen.dart';
import '../../domain/entities/solicitud_resumen.dart';
import '../providers/solicitud_providers.dart';
import 'nueva_solicitud_screen.dart';
import 'solicitud_detalle_screen.dart';

/// G02 — HU-03. "Mis solicitudes", con `AppOrderCard`/`AppStatusPill`
/// (mismo lenguaje visual que el resto del rediseño) y un filtro
/// Activas/Historial: Historial son las que ya no van a cambiar de
/// estado (`entregado`/`cancelada`), Activas todo lo demás.
class MisSolicitudesScreen extends ConsumerStatefulWidget {
  const MisSolicitudesScreen({super.key});

  static const routeName = '/solicitudes';

  @override
  ConsumerState<MisSolicitudesScreen> createState() => _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends ConsumerState<MisSolicitudesScreen> {
  static const _estadosHistorial = {'entregado', 'cancelada'};

  bool _cargando = true;
  List<SolicitudResumen>? _solicitudes;
  String? _error;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// G01 — no se puede ni empezar una solicitud nueva si el perfil
  /// todavía no tiene foto de cédula cargada (HU-02); la API igual lo
  /// bloquea (403), pero se evita el viaje mandando directo a completar
  /// el perfil.
  Future<void> _onNuevaSolicitud() async {
    String? errorPerfil;
    bool tieneCedula = false;
    try {
      final perfil = await ref.read(obtenerPerfilUseCaseProvider).execute();
      tieneCedula = perfil.paciente?.fotoCedulaUrl != null;
    } on ApiException catch (error) {
      errorPerfil = error.message;
    } on ApiSinConexionException catch (error) {
      errorPerfil = error.toString();
    }

    if (!mounted) return;

    if (errorPerfil != null) {
      setState(() => _error = errorPerfil);
      return;
    }

    if (!tieneCedula) {
      final ir = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Completa tu perfil'),
          content: const Text(
            'Necesitás una foto de tu cédula en tu perfil antes de crear una solicitud.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ahora no'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ir a Mi perfil'),
            ),
          ],
        ),
      );
      if (ir == true && mounted) {
        await Navigator.of(context).pushNamed(PerfilScreen.routeName);
      }
      return;
    }

    await Navigator.of(context).pushNamed(NuevaSolicitudScreen.routeName);
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final solicitudes = await ref.read(listarSolicitudesUseCaseProvider).execute();
      if (!mounted) return;
      setState(() => _solicitudes = solicitudes);
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
    final todas = _solicitudes ?? const <SolicitudResumen>[];
    final esHistorial = _tab == 1;
    final visibles = todas
        .where((s) => _estadosHistorial.contains(s.estado) == esHistorial)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis solicitudes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onNuevaSolicitud,
        icon: const Icon(Icons.add),
        label: const Text('Nueva solicitud'),
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                    children: [
                      if (_error != null) ...[
                        AppErrorBanner(mensaje: _error!),
                        const SizedBox(height: 16),
                      ],
                      AppSegmentedTabs(
                        opciones: const ['Activas', 'Historial'],
                        seleccionado: _tab,
                        onSeleccionar: (i) => setState(() => _tab = i),
                      ),
                      const SizedBox(height: 16),
                      if (visibles.isEmpty && _error == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            _tab == 0
                                ? 'No tenés solicitudes activas. Creá una con el botón de abajo.'
                                : 'Todavía no hay solicitudes en tu historial.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.teal),
                          ),
                        ),
                      for (final solicitud in visibles) ...[
                        AppOrderCard(
                          titulo: solicitud.codigoPedido ??
                              'Solicitud del ${_formatearFecha(solicitud.creadoEn)}',
                          subtitulo: solicitud.codigoPedido == null
                              ? 'Sin enviar todavía'
                              : _formatearFecha(solicitud.creadoEn),
                          estado: solicitud.estado,
                          onTap: () async {
                            await Navigator.of(context).pushNamed(
                              SolicitudDetalleScreen.routeName,
                              arguments: solicitud.id,
                            );
                            _cargar();
                          },
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
  final fecha = DateTime.tryParse(iso);
  if (fecha == null) return iso;
  final dia = fecha.day.toString().padLeft(2, '0');
  const meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  return '$dia ${meses[fecha.month - 1]} ${fecha.year}';
}
