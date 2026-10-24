import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/core/network/api_exception.dart';
import '../../../shared/core/theme/app_colors.dart';
import '../../../shared/widgets/app_error_banner.dart';
import '../../usuarios/presentation/widgets/main_bottom_bar.dart';
import '../domain/notificacion.dart';
import 'navegar_notificacion.dart';
import 'notificaciones_provider.dart';
import '../../../shared/core/theme/modo_alto_contraste_provider.dart';
import '../../../shared/core/theme/modo_oscuro_provider.dart';

class NotificacionesScreen extends ConsumerStatefulWidget {
  const NotificacionesScreen({super.key});

  static const routeName = '/notificaciones';

  @override
  ConsumerState<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends ConsumerState<NotificacionesScreen> {
  bool _cargando = true;
  String? _error;
  List<Notificacion> _items = const [];

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
      final items = await ref.read(notificacionesDatasourceProvider).listar();
      if (!mounted) return;
      setState(() {
        _items = items;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _mensajeError(error);
        _cargando = false;
      });
    }
  }

  String _mensajeError(Object error) {
    if (error is ApiException && error.statusCode < 500) {
      final mensaje = error.message.trim();
      if (mensaje.isNotEmpty &&
          mensaje != 'Internal Server Error' &&
          !mensaje.toLowerCase().contains('cannot get')) {
        return mensaje;
      }
    }
    return 'No se pudieron cargar las notificaciones.';
  }

  Future<void> _abrir(Notificacion item) async {
    if (!item.leida) {
      try {
        await ref.read(notificacionesDatasourceProvider).marcarLeida(item.id);
        if (!mounted) return;
        setState(() {
          _items = [
            for (final actual in _items)
              if (actual.id == item.id)
                Notificacion(
                  id: actual.id,
                  tipo: actual.tipo,
                  titulo: actual.titulo,
                  mensaje: actual.mensaje,
                  referenciaTipo: actual.referenciaTipo,
                  referenciaId: actual.referenciaId,
                  leida: true,
                  creadoEn: actual.creadoEn,
                )
              else
                actual,
          ];
        });
      } catch (_) {
        // Seguir al destino igual: el listado se puede marcar después.
      }
    }

    if (!mounted) return;
    await navegarNotificacion(context, ref.read, tipo: item.tipo, referenciaId: item.referenciaId);
  }

  @override
  Widget build(BuildContext context) {
    // Fuerza repintar esta pantalla ya montada cuando se togglea modo
    // oscuro/alto contraste desde Perfil (ver AppColors.configurar en
    // main.dart) — sin este watch, Riverpod no sabría que repintar.
    ref.watch(modoOscuroProvider);
    ref.watch(modoAltoContrasteProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'Notificaciones',
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
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.navy, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                    children: [
                      if (_error != null) ...[
                        AppErrorBanner(mensaje: _error!),
                        const SizedBox(height: 16),
                      ],
                      if (_error == null && _items.isEmpty)
                        const _VacioNotificaciones()
                      else
                        for (final item in _items) ...[
                          _TarjetaNotificacion(
                            item: item,
                            cuando: _hace(item.creadoEn),
                            onTap: () => _abrir(item),
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

  String _hace(DateTime fecha) {
    final diferencia = DateTime.now().difference(fecha);
    if (diferencia.isNegative || diferencia.inSeconds < 60) {
      return 'Hace un momento';
    }
    if (diferencia.inMinutes < 60) {
      final minutos = diferencia.inMinutes;
      return minutos == 1 ? 'Hace 1 minuto' : 'Hace $minutos minutos';
    }
    if (diferencia.inHours < 24) {
      final horas = diferencia.inHours;
      return horas == 1 ? 'Hace 1 hora' : 'Hace $horas horas';
    }
    if (diferencia.inDays == 1) return 'Ayer';
    if (diferencia.inDays < 7) return 'Hace ${diferencia.inDays} días';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
  }
}

class _TarjetaNotificacion extends StatelessWidget {
  const _TarjetaNotificacion({
    required this.item,
    required this.cuando,
    required this.onTap,
  });

  final Notificacion item;
  final String cuando;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nueva = !item.leida;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: nueva ? null : AppColors.white,
          gradient: nueva
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.gradienteSutil,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: nueva
                ? AppColors.skyBlue.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.skyBlue.withValues(alpha: nueva ? 0.55 : 0.3),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: nueva ? AppColors.navy : AppColors.teal,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.titulo,
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 16,
                            fontWeight: nueva ? FontWeight.w800 : FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (nueva) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.mensaje,
                    style: TextStyle(
                      color: nueva ? AppColors.teal : Colors.grey,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cuando,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VacioNotificaciones extends StatelessWidget {
  const _VacioNotificaciones();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
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
              Icons.notifications_none_rounded,
              color: AppColors.navy,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Todavía no hay notificaciones',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cuando tengas novedades sobre tus pedidos aparecerán aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.teal, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
