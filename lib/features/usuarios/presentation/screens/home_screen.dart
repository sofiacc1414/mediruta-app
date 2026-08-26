import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_promo_banner.dart';
import '../../../../shared/widgets/app_stat_tile.dart';
import '../../../../shared/widgets/app_status_pill.dart';
import '../../../solicitudes/domain/entities/pedido_activo.dart';
import '../../../solicitudes/domain/entities/solicitud_resumen.dart';
import '../../../solicitudes/presentation/providers/solicitud_providers.dart';
import '../../../solicitudes/presentation/screens/mi_pedido_activo_screen.dart';
import '../../../solicitudes/presentation/screens/mis_solicitudes_screen.dart';
import '../../../solicitudes/presentation/screens/pedidos_disponibles_screen.dart';
import '../../../solicitudes/presentation/screens/solicitud_detalle_screen.dart';
import '../../domain/entities/perfil.dart';
import '../../domain/entities/rol_asignado.dart';
import '../providers/auth_session_provider.dart';
import '../providers/disponibilidad_domiciliario_provider.dart';
import '../providers/perfil_providers.dart';
import '../widgets/main_bottom_bar.dart';

/// HU-03/HU-09/HU-07 — pantalla de inicio del rol activo.
///
/// v5, a pedido explícito de corrección sobre v4: la barra inferior
/// (`MainBottomBar`) deja de vivir solo acá — es persistente en toda
/// la app, cada pantalla principal la agrega. El selector de modo
/// (Paciente/Domiciliario) también se mudó a la barra; acá solo queda
/// el contenido específico del modo activo. "Disponible" pasó a ser
/// estado compartido (`disponibilidadDomiciliarioProvider`) en vez de
/// local de esta pantalla, porque la barra necesita saber si el
/// Domiciliario está en línea sin importar en qué pantalla esté
/// parado. Paleta y tipografía oficiales sin cambios.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Perfil? _perfil;

  bool _cargandoPaciente = false;
  int _activas = 0;
  int _entregadosMes = 0;
  SolicitudResumen? _solicitudActiva;
  String? _errorPaciente;

  bool _cargandoDomiciliario = false;
  PedidoActivo? _pedidoActivo;
  String? _errorDomiciliario;

  String? _modoCargado;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarSegunModo());
  }

  Future<void> _cargarPerfil() async {
    try {
      final perfil = await ref.read(obtenerPerfilUseCaseProvider).execute();
      if (!mounted) return;
      setState(() => _perfil = perfil);
    } on ApiException {
      // Silencioso a propósito: el saludo cae a "Hola" sin nombre si
      // esto falla — no vale la pena tapar toda la pantalla por un
      // dato de encabezado que no es crítico.
    } on ApiSinConexionException {
      // idem
    }
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
      const estadosTerminales = {'entregado', 'cancelada', 'borrador'};
      setState(() {
        final activas = solicitudes.where((s) => !estadosTerminales.contains(s.estado)).toList();
        _activas = activas.length;
        // La más reciente en curso es la que más le importa a la
        // persona ahora mismo — protagonista del hero, no un número
        // más en una lista.
        _solicitudActiva = activas.isEmpty ? null : activas.first;
        _entregadosMes = solicitudes.where((s) {
          if (s.estado != 'entregado') return false;
          final fecha = DateTime.tryParse(s.creadoEn)?.toLocal();
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

  Future<void> _cargarTodo() => Future.wait([_cargarPerfil(), _cargarSegunModo()]);

  String _saludoDelMomento() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buen día';
    if (hora < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(authSessionProvider);
    final usuario = estado is AuthAutenticado ? estado.usuario : null;
    final roles = usuario?.roles ?? const <RolAsignado>[];
    final modo = ref.watch(modoActivoProvider) ?? (roles.isNotEmpty ? roles.first.codigo : null);
    final esPaciente = modo == 'PACIENTE';
    final esDomiciliario = modo == 'DOMICILIARIO';

    // El modo puede cambiar desde el toggle de `MainBottomBar` — se
    // detecta en cada build y se dispara la carga correspondiente
    // después del frame (evita `setState` durante `build`).
    if (modo != _modoCargado) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _cargarSegunModo());
    }

    return Scaffold(
      bottomNavigationBar: const MainBottomBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarTodo,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _Encabezado(
                    saludo: _saludoDelMomento(),
                    nombre: _perfil?.nombreCompleto ?? usuario?.correo,
                    fotoUrl: _perfil?.fotoPerfilUrl,
                    onTap: () => Navigator.of(context).pushNamed('/perfil'),
                  ),
                  const SizedBox(height: 24),
                  if (esPaciente) ..._contenidoPaciente(context),
                  if (esDomiciliario) ..._contenidoDomiciliario(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _contenidoPaciente(BuildContext context) {
    final solicitud = _solicitudActiva;
    return [
      if (_errorPaciente != null) ...[
        AppErrorBanner(mensaje: _errorPaciente!),
        const SizedBox(height: 16),
      ],
      if (_cargandoPaciente)
        const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
      else if (solicitud != null)
        // Protagonista: el pedido que ya tiene en curso, no un banner
        // genérico invitándola a pedir algo que ya pidió.
        _TarjetaHero(
          onTap: () async {
            await Navigator.of(context).pushNamed(
              SolicitudDetalleScreen.routeName,
              arguments: solicitud.id,
            );
            _cargarStatsPaciente();
          },
          eyebrow: 'Tu pedido en curso',
          titulo: solicitud.codigoPedido ?? 'Solicitud enviada',
          trailing: AppStatusPill(estado: solicitud.estado),
          accion: 'Ver seguimiento',
        )
      else
        AppPromoBanner(
          titulo: '¿Necesitás pedir tus medicamentos?',
          icono: Icons.medication_outlined,
          accion: 'Nueva solicitud',
          onTapAccion: () => Navigator.of(context).pushNamed(MisSolicitudesScreen.routeName),
        ),
      const SizedBox(height: 16),
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
      Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).pushNamed(MisSolicitudesScreen.routeName),
          child: const Text('Ver todas mis solicitudes'),
        ),
      ),
    ];
  }

  List<Widget> _contenidoDomiciliario(BuildContext context) {
    final disponibilidad = ref.watch(disponibilidadDomiciliarioProvider);
    return [
      // El switch "Disponible" es la decisión más importante de esta
      // pantalla para el Domiciliario — protagonista, con un estado
      // visual bien distinto entre apagado (calmo, outline) y
      // encendido (fill navy, "en línea").
      _TarjetaDisponibilidad(
        disponible: disponibilidad.disponible,
        actualizando: disponibilidad.actualizando,
        onChanged: (valor) => ref.read(disponibilidadDomiciliarioProvider.notifier).cambiar(valor),
      ),
      if (disponibilidad.error != null) ...[
        const SizedBox(height: 12),
        AppErrorBanner(mensaje: disponibilidad.error!),
      ],
      const SizedBox(height: 16),
      if (_errorDomiciliario != null) ...[
        AppErrorBanner(mensaje: _errorDomiciliario!),
        const SizedBox(height: 16),
      ],
      if (_cargandoDomiciliario)
        const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
      else if (_pedidoActivo != null)
        _TarjetaHero(
          onTap: () async {
            await Navigator.of(context).pushNamed(MiPedidoActivoScreen.routeName);
            _cargarPedidoActivoDomiciliario();
          },
          eyebrow: 'Pedido activo',
          titulo: _pedidoActivo!.codigoPedido ?? 'Pedido en curso',
          trailing: AppStatusPill(estado: _pedidoActivo!.estado),
          accion: 'Continuar entrega',
        )
      else if (disponibilidad.disponible)
        AppPromoBanner(
          titulo: 'Buscá pedidos cerca tuyo',
          icono: Icons.moped_outlined,
          accion: 'Ver pedidos disponibles',
          onTapAccion: () => Navigator.of(context).pushNamed(PedidosDisponiblesScreen.routeName),
        )
      else
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Activá "Disponible" para empezar a recibir pedidos cerca tuyo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.teal),
          ),
        ),
    ];
  }
}

/// Encabezado de identidad: avatar + nombre + saludo del momento, como
/// una sola unidad tappable hacia el perfil — reemplaza la fila suelta
/// de "Hola, {correo}" + ícono de perfil aparte.
class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.saludo,
    required this.nombre,
    required this.fotoUrl,
    required this.onTap,
  });

  final String saludo;
  final String? nombre;
  final String? fotoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _Avatar(fotoUrl: fotoUrl, nombre: nombre),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(saludo, style: const TextStyle(color: AppColors.teal)),
                  Text(
                    nombre ?? 'Sesión activa',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.teal),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.fotoUrl, required this.nombre});

  final String? fotoUrl;
  final String? nombre;

  @override
  Widget build(BuildContext context) {
    const tamano = 52.0;
    return ClipOval(
      child: fotoUrl != null
          ? Image.network(
              fotoUrl!,
              width: tamano,
              height: tamano,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _iniciales(tamano);
              },
              errorBuilder: (context, error, stackTrace) => _iniciales(tamano),
            )
          : _iniciales(tamano),
    );
  }

  Widget _iniciales(double tamano) {
    final letra = (nombre != null && nombre!.trim().isNotEmpty)
        ? nombre!.trim()[0].toUpperCase()
        : '?';
    return Container(
      width: tamano,
      height: tamano,
      color: AppColors.skyBlue,
      alignment: Alignment.center,
      child: Text(
        letra,
        style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 20),
      ),
    );
  }
}

/// Tarjeta protagonista: para el pedido que ya está en curso, sea del
/// Paciente o del Domiciliario — fondo navy sólido a propósito, para
/// que gane frente a cualquier otro elemento de la pantalla.
class _TarjetaHero extends StatelessWidget {
  const _TarjetaHero({
    required this.eyebrow,
    required this.titulo,
    required this.trailing,
    required this.accion,
    required this.onTap,
  });

  final String eyebrow;
  final String titulo;
  final Widget trailing;
  final String accion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    eyebrow.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.skyBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                trailing,
              ],
            ),
            const SizedBox(height: 10),
            Text(
              titulo,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  accion,
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, color: AppColors.white, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// El switch "Disponible" como protagonista de la pantalla del
/// Domiciliario — dos estados bien distintos: apagado (calmo, blanco
/// con borde) y encendido (fill navy, "en línea").
class _TarjetaDisponibilidad extends StatelessWidget {
  const _TarjetaDisponibilidad({
    required this.disponible,
    required this.actualizando,
    required this.onChanged,
  });

  final bool disponible;
  final bool actualizando;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: disponible ? AppColors.navy : AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: disponible ? null : Border.all(color: AppColors.skyBlue, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: disponible ? AppColors.white.withValues(alpha: 0.15) : AppColors.beige,
            ),
            child: Icon(
              disponible ? Icons.bolt : Icons.bolt_outlined,
              color: disponible ? AppColors.white : AppColors.navy,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disponible ? 'Estás en línea' : 'Disponible para recibir pedidos',
                  style: TextStyle(
                    color: disponible ? AppColors.white : AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  disponible ? 'Vas a aparecer en el pool de pedidos.' : 'Estás fuera de línea.',
                  style: TextStyle(
                    color: disponible ? AppColors.skyBlue : AppColors.teal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          actualizando
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: disponible ? AppColors.white : AppColors.navy,
                  ),
                )
              : Switch(value: disponible, onChanged: onChanged),
        ],
      ),
    );
  }
}
