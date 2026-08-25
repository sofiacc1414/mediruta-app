import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_promo_banner.dart';
import '../../../../shared/widgets/app_segmented_tabs.dart';
import '../../../../shared/widgets/app_stat_tile.dart';
import '../../../../shared/widgets/app_status_pill.dart';
import '../../../solicitudes/domain/entities/pedido_activo.dart';
import '../../../solicitudes/presentation/providers/solicitud_providers.dart';
import '../../../solicitudes/presentation/screens/mi_pedido_activo_screen.dart';
import '../../../solicitudes/presentation/screens/mis_solicitudes_screen.dart';
import '../../../solicitudes/presentation/screens/pedidos_disponibles_screen.dart';
import '../../domain/entities/rol_asignado.dart';
import '../providers/auth_session_provider.dart';
import '../providers/perfil_providers.dart';

/// HU-03/HU-09/HU-07 — pantalla de inicio del rol activo (rediseño tipo
/// "app de pedidos", context.md Parte A). El selector de "Modo" (cuando
/// la cuenta tiene los 2 roles) usa `AppSegmentedTabs` — la API siempre
/// determina los permisos reales consultando `usuario_roles`, esto es
/// solo una decisión de presentación (context.md, Parte B, sección 4.1).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _etiquetasRol = {'PACIENTE': 'Paciente', 'DOMICILIARIO': 'Domiciliario'};

  bool _cargandoPaciente = false;
  int _activas = 0;
  int _entregadosMes = 0;
  String? _errorPaciente;

  bool _cargandoDomiciliario = false;
  PedidoActivo? _pedidoActivo;
  String? _errorDomiciliario;

  // "Disponible" arranca apagado en cada apertura de la app (mismo
  // criterio que la mayoría de apps de repartidores: no asumir
  // disponibilidad de una sesión anterior) — la API no expone todavía
  // el valor guardado en un GET de perfil, así que no hay de dónde
  // leer el estado real al abrir.
  bool _disponible = false;
  bool _actualizandoDisponibilidad = false;
  String? _errorDisponibilidad;

  String? _modoCargado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarSegunModo());
  }

  String? _modoActual() {
    final estado = ref.read(authSessionProvider);
    final usuario = estado is AuthAutenticado ? estado.usuario : null;
    final roles = usuario?.roles ?? const <RolAsignado>[];
    return ref.read(modoActivoProvider) ?? (roles.isNotEmpty ? roles.first.codigo : null);
  }

  Future<void> _cargarSegunModo() async {
    final modo = _modoActual();
    if (modo == _modoCargado) return;
    _modoCargado = modo;
    if (modo == 'PACIENTE') {
      await _cargarStatsPaciente();
    } else if (modo == 'DOMICILIARIO') {
      await _cargarPedidoActivoDomiciliario();
    }
  }

  Future<void> _cargarStatsPaciente() async {
    setState(() {
      _cargandoPaciente = true;
      _errorPaciente = null;
    });
    try {
      final solicitudes = await ref.read(listarSolicitudesUseCaseProvider).execute();
      if (!mounted) return;
      final ahora = DateTime.now();
      setState(() {
        _activas = solicitudes
            .where((s) => s.estado != 'entregado' && s.estado != 'cancelada' && s.estado != 'borrador')
            .length;
        _entregadosMes = solicitudes.where((s) {
          if (s.estado != 'entregado') return false;
          final fecha = DateTime.tryParse(s.creadoEn);
          return fecha != null && fecha.year == ahora.year && fecha.month == ahora.month;
        }).length;
      });
    } on ApiException catch (error) {
      setState(() => _errorPaciente = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _errorPaciente = error.toString());
    } finally {
      if (mounted) setState(() => _cargandoPaciente = false);
    }
  }

  Future<void> _cargarPedidoActivoDomiciliario() async {
    setState(() {
      _cargandoDomiciliario = true;
      _errorDomiciliario = null;
    });
    try {
      final pedido = await ref.read(obtenerPedidoActivoUseCaseProvider).execute();
      if (!mounted) return;
      setState(() => _pedidoActivo = pedido);
    } on ApiException catch (error) {
      setState(() => _errorDomiciliario = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _errorDomiciliario = error.toString());
    } finally {
      if (mounted) setState(() => _cargandoDomiciliario = false);
    }
  }

  /// Al activar, pide permiso de ubicación y lee la posición actual —
  /// obligatoria para entrar al pool (`app.listar_pedidos_disponibles`
  /// filtra por `ubicacion`). Al desactivar no hace falta ubicación.
  Future<void> _cambiarDisponibilidad(bool valor) async {
    setState(() {
      _actualizandoDisponibilidad = true;
      _errorDisponibilidad = null;
    });
    try {
      double? lat;
      double? lng;
      if (valor) {
        final posicion = await _obtenerUbicacionActual();
        if (posicion == null) {
          setState(() {
            _errorDisponibilidad =
                'Necesitamos permiso de ubicación para activar "Disponible".';
            _actualizandoDisponibilidad = false;
          });
          return;
        }
        lat = posicion.latitude;
        lng = posicion.longitude;
      }
      await ref
          .read(actualizarDisponibilidadDomiciliarioUseCaseProvider)
          .execute(disponible: valor, lat: lat, lng: lng);
      if (!mounted) return;
      setState(() => _disponible = valor);
    } on ApiException catch (error) {
      setState(() => _errorDisponibilidad = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _errorDisponibilidad = error.toString());
    } finally {
      if (mounted) setState(() => _actualizandoDisponibilidad = false);
    }
  }

  Future<Position?> _obtenerUbicacionActual() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(authSessionProvider);
    final usuario = estado is AuthAutenticado ? estado.usuario : null;
    final roles = usuario?.roles ?? const <RolAsignado>[];
    final modo = ref.watch(modoActivoProvider) ?? (roles.isNotEmpty ? roles.first.codigo : null);
    final esPaciente = modo == 'PACIENTE';
    final esDomiciliario = modo == 'DOMICILIARIO';

    // El modo puede cambiar por el AppSegmentedTabs de acá abajo — se
    // detecta en cada build y se dispara la carga correspondiente
    // después del frame (evita `setState` durante `build`).
    if (modo != _modoCargado) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _cargarSegunModo());
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarSegunModo,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hola,', style: TextStyle(color: AppColors.teal)),
                            Text(
                              usuario?.correo ?? 'Sesión activa',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_outline, color: AppColors.navy),
                        onPressed: () => Navigator.of(context).pushNamed('/perfil'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (roles.length > 1) ...[
                    AppSegmentedTabs(
                      opciones: [for (final rol in roles) _etiquetasRol[rol.codigo] ?? rol.codigo],
                      seleccionado: roles.indexWhere((r) => r.codigo == modo).clamp(0, roles.length - 1),
                      onSeleccionar: (i) =>
                          ref.read(modoActivoProvider.notifier).state = roles[i].codigo,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (esPaciente) ..._contenidoPaciente(context),
                  if (esDomiciliario) ..._contenidoDomiciliario(context),
                  const SizedBox(height: 28),
                  AppButton(
                    variante: AppButtonVariante.secondary,
                    onPressed: () async {
                      await ref.read(authSessionProvider.notifier).cerrarSesion();
                      ref.invalidate(modoActivoProvider);
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
                      }
                    },
                    label: 'Cerrar sesión',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _contenidoPaciente(BuildContext context) {
    return [
      if (_errorPaciente != null) ...[
        AppErrorBanner(mensaje: _errorPaciente!),
        const SizedBox(height: 16),
      ],
      if (_cargandoPaciente)
        const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
      else
        Row(
          children: [
            Expanded(
              child: AppStatTile(
                icono: Icons.local_shipping_outlined,
                valor: '$_activas',
                label: 'Pedidos activos',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppStatTile(
                icono: Icons.check_circle_outline,
                valor: '$_entregadosMes',
                label: 'Entregados este mes',
              ),
            ),
          ],
        ),
      const SizedBox(height: 16),
      AppPromoBanner(
        titulo: '¿Necesitás pedir tus medicamentos?',
        icono: Icons.medication_outlined,
        accion: 'Nueva solicitud',
        onTapAccion: () => Navigator.of(context).pushNamed(MisSolicitudesScreen.routeName),
      ),
      const SizedBox(height: 16),
      AppButton(
        variante: AppButtonVariante.secondary,
        label: 'Mis solicitudes',
        onPressed: () => Navigator.of(context).pushNamed(MisSolicitudesScreen.routeName),
      ),
    ];
  }

  List<Widget> _contenidoDomiciliario(BuildContext context) {
    return [
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Disponible para recibir pedidos',
                    style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _disponible ? 'Vas a aparecer en el pool de pedidos.' : 'Estás fuera de línea.',
                    style: const TextStyle(color: AppColors.teal, fontSize: 12),
                  ),
                ],
              ),
            ),
            _actualizandoDisponibilidad
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch(value: _disponible, onChanged: _cambiarDisponibilidad),
          ],
        ),
      ),
      if (_errorDisponibilidad != null) ...[
        const SizedBox(height: 12),
        AppErrorBanner(mensaje: _errorDisponibilidad!),
      ],
      const SizedBox(height: 16),
      if (_errorDomiciliario != null) ...[
        AppErrorBanner(mensaje: _errorDomiciliario!),
        const SizedBox(height: 16),
      ],
      if (_cargandoDomiciliario)
        const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
      else if (_pedidoActivo != null)
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
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              await Navigator.of(context).pushNamed(MiPedidoActivoScreen.routeName);
              _cargarPedidoActivoDomiciliario();
            },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pedidoActivo!.codigoPedido ?? 'Pedido en curso',
                        style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      AppStatusPill(estado: _pedidoActivo!.estado),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.navy),
              ],
            ),
          ),
        )
      else
        AppPromoBanner(
          titulo: 'Buscá pedidos cerca tuyo',
          icono: Icons.moped_outlined,
          accion: 'Ver pedidos disponibles',
          onTapAccion: () => Navigator.of(context).pushNamed(PedidosDisponiblesScreen.routeName),
        ),
    ];
  }
}
