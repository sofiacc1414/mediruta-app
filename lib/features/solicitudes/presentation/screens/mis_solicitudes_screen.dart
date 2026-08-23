import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_icon_badge.dart';
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
                          onPressed: () async {
                            await Navigator.of(
                              context,
                            ).pushNamed(NuevaSolicitudScreen.routeName);
                            _cargar();
                          },
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
                    solicitud.medicamentoNombre ?? 'Sin nombre de medicamento',
                    style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _etiquetasEstado[solicitud.estado] ?? solicitud.estado,
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
