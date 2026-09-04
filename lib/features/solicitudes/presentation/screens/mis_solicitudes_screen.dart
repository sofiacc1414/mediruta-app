import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../usuarios/presentation/providers/perfil_providers.dart';
import '../../../usuarios/presentation/screens/perfil_screen.dart';
import '../../../usuarios/presentation/widgets/main_bottom_bar.dart';
import '../../domain/entities/solicitud_resumen.dart';
import '../providers/solicitud_providers.dart';
import 'nueva_solicitud_screen.dart';
import 'solicitud_detalle_screen.dart';

/// G02 — HU-03. "Mis solicitudes", con filtro Activas/Historial.
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

  Future<void> _onNuevaSolicitud() async {
    String? errorPerfil;
    bool tieneCedula = false;
    try {
      final perfil = await ref.read(obtenerPerfilUseCaseProvider).execute();
      tieneCedula =
          perfil.paciente?.fotoCedulaFrenteUrl != null &&
          perfil.paciente?.fotoCedulaReversoUrl != null;
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Completa tu perfil', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700)),
          content: const Text(
            'Necesitás una foto de tu cédula en tu perfil antes de crear una solicitud.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ahora no', style: TextStyle(color: AppColors.navy)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ir a Mi perfil', style: TextStyle(color: AppColors.teal)),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Mis solicitudes',
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
          onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
        ),
      ),
      bottomNavigationBar: const MainBottomBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onNuevaSolicitud,
        backgroundColor: const Color(0xFFE3E8EF),
        foregroundColor: AppColors.navy,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.add),
        label: const Text('Nueva solicitud', style: TextStyle(fontWeight: FontWeight.w600)),
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

                      // ====== FILTRO ESTILIZADO ======
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _OpcionTab(
                              texto: 'Activas',
                              seleccionado: _tab == 0,
                              onTap: () => setState(() => _tab = 0),
                            ),
                            _OpcionTab(
                              texto: 'Historial',
                              seleccionado: _tab == 1,
                              onTap: () => setState(() => _tab = 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (visibles.isEmpty && _error == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.skyBlue.withValues(alpha: 0.2),
                                ),
                                child: Icon(
                                  _tab == 0
                                      ? Icons.inbox_outlined
                                      : Icons.history,
                                  color: AppColors.navy,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _tab == 0
                                    ? 'No tenés solicitudes activas. Creá una con el botón de abajo.'
                                    : 'Todavía no hay solicitudes en tu historial.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.teal),
                              ),
                            ],
                          ),
                        ),

                      // ====== TARJETAS ESTILIZADAS ======
                      for (final solicitud in visibles) ...[
                        _TarjetaSolicitud(
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

// ==================== WIDGETS VISUALES INTERNOS ====================

/// Filtro estilo "Segmented Control"
class _OpcionTab extends StatelessWidget {
  const _OpcionTab({
    required this.texto,
    required this.seleccionado,
    required this.onTap,
  });

  final String texto;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: seleccionado ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: seleccionado
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              texto,
              style: TextStyle(
                color: seleccionado ? AppColors.navy : Colors.grey,
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

/// Tarjeta de solicitud con la imagen del repartidor en moto
class _TarjetaSolicitud extends StatelessWidget {
  const _TarjetaSolicitud({
    required this.titulo,
    required this.subtitulo,
    required this.estado,
    required this.onTap,
  });

  final String titulo;
  final String subtitulo;
  final String estado;
  final VoidCallback onTap;

  // Convierte el estado de la API a un texto visible y una lógica booleana
  (String, bool) _textoYEstado() {
    if (estado == 'entregado' || estado == 'completado' || estado == 'aceptado' || estado == 'asignado') {
      return ('Asignado', true);
    } else if (estado == 'cancelada' || estado == 'rechazado') {
      return ('Asignación pendiente', false);
    } else {
      return ('Asignación pendiente', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (textoEstado, esAsignado) = _textoYEstado();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Imagen del repartidor en moto
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/repartidor_moto.png', // RECUERDA GUARDAR TU IMAGEN AQUÍ
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.local_shipping_outlined, color: AppColors.navy, size: 26),
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
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Botón tipo píldora gris claro con letra azul oscuro
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                textoEstado,
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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