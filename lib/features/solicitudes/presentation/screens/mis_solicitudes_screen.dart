import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_icon_badge.dart';
import '../../../usuarios/presentation/providers/perfil_providers.dart';
import '../../../usuarios/presentation/screens/perfil_screen.dart';
import '../../domain/entities/solicitud_resumen.dart';
import '../providers/solicitud_providers.dart';
import 'nueva_solicitud_screen.dart';
import 'solicitud_detalle_screen.dart';

const _etiquetasEstado = {
  'borrador': 'Borrador',
  'pendiente_revision': 'Pendiente de revisión',
  'cancelada': 'Cancelada',
};

/// G02 — HU-03. "Mis solicitudes".
class MisSolicitudesScreen extends ConsumerStatefulWidget {
  const MisSolicitudesScreen({super.key});

  static const routeName = '/solicitudes';

  @override
  ConsumerState<MisSolicitudesScreen> createState() => _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends ConsumerState<MisSolicitudesScreen> {
  bool _cargando = true;
  List<SolicitudResumen>? _solicitudes;
  String? _error;

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
    return Scaffold(
      appBar: AppBar(title: const Text('Mis solicitudes')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: RefreshIndicator(
                  onRefresh: _cargar,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                        if ((_solicitudes?.isEmpty ?? false) && _error == null)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'Todavía no tenés solicitudes. Creá la primera con el botón de abajo.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.teal),
                            ),
                          ),
                        for (final solicitud in _solicitudes ?? []) ...[
                          _FilaSolicitud(
                            solicitud: solicitud,
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
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'Nueva solicitud',
                          onPressed: _onNuevaSolicitud,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _FilaSolicitud extends StatelessWidget {
  const _FilaSolicitud({required this.solicitud, required this.onTap});

  final SolicitudResumen solicitud;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.skyBlue),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    solicitud.codigoPedido ?? 'Solicitud del ${_formatearFecha(solicitud.creadoEn)}',
                    style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    solicitud.codigoPedido == null
                        ? (_etiquetasEstado[solicitud.estado] ?? solicitud.estado)
                        : '${_etiquetasEstado[solicitud.estado] ?? solicitud.estado} · ${_formatearFecha(solicitud.creadoEn)}',
                    style: const TextStyle(color: AppColors.teal, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.navy),
          ],
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
