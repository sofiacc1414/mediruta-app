import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_status_pill.dart';
import '../../../solicitudes/domain/entities/pedido_activo.dart';
import '../../../solicitudes/domain/entities/solicitud_resumen.dart';
import '../../../solicitudes/presentation/providers/solicitud_providers.dart';
import '../../../solicitudes/presentation/screens/historial_pedidos_screen.dart';
import '../../../solicitudes/presentation/screens/mi_pedido_activo_screen.dart';
import '../../../solicitudes/presentation/screens/mis_solicitudes_screen.dart';
import '../../../solicitudes/presentation/screens/pedidos_disponibles_screen.dart';
import '../../../solicitudes/presentation/screens/solicitud_detalle_screen.dart';
import '../../domain/entities/perfil.dart';
import '../../domain/entities/rol_asignado.dart';
import '../providers/auth_session_provider.dart';
import '../providers/disponibilidad_domiciliario_provider.dart';
import '../providers/perfil_providers.dart';
import '../widgets/boton_cambiar_modo.dart';
import '../widgets/main_bottom_bar.dart';

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
    } on ApiSinConexionException {
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

    if (modo != _modoCargado) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _cargarSegunModo());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const MainBottomBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarTodo,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _Encabezado(
                    saludo: _saludoDelMomento(),
                    nombre: _perfil?.nombreCompleto ?? usuario?.correo,
                    fotoUrl: _perfil?.fotoPerfilUrl,
                    modoEtiqueta: esDomiciliario
                        ? 'Estás en modo Domiciliario'
                        : (esPaciente ? 'Estás en modo Paciente' : null),
                  ),
                  const SizedBox(height: 24),

                  // Tarjeta Hero personalizada según el rol
                  if (esDomiciliario)
                    const _TarjetaHeroBienvenidaDomiciliario()
                  else
                    const _TarjetaHeroBienvenida(
                      titulo: 'Tu salud en movimiento',
                      descripcion: 'Recibe tus medicamentos en la puerta de tu casa con MediRuta.',
                      imagenAsset: 'assets/images/hero_delivery.png',
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
      const Text(
        'Mis pedidos',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
      const SizedBox(height: 12),

      if (_errorPaciente != null) ...[
        AppErrorBanner(mensaje: _errorPaciente!),
        const SizedBox(height: 16),
      ],
      if (_cargandoPaciente)
        const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
      else ...[
        if (solicitud != null) ...[
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
          ),
          const SizedBox(height: 16),
        ],
        
        _TarjetaPedirMedicamentos(
          onTap: () => Navigator.of(context).pushNamed(MisSolicitudesScreen.routeName),
        ),
        const SizedBox(height: 16),
      ],

      Row(
        children: [
          Expanded(
            child: _TarjetaStats(
              icono: Icons.local_shipping_outlined,
              valor: '$_activas',
              label: 'Pedidos activos',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TarjetaStats(
              icono: Icons.check_circle_outline,
              valor: '$_entregadosMes',
              label: 'Entregados este mes',
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _contenidoDomiciliario(BuildContext context) {
    final disponibilidad = ref.watch(disponibilidadDomiciliarioProvider);
    return [
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
      else ...[
        // Pedido activo (si existe)
        if (_pedidoActivo != null) ...[
          _TarjetaHero(
            onTap: () async {
              await Navigator.of(context).pushNamed(MiPedidoActivoScreen.routeName);
              _cargarPedidoActivoDomiciliario();
            },
            eyebrow: 'Pedido activo',
            titulo: _pedidoActivo!.codigoPedido ?? 'Pedido en curso',
            trailing: AppStatusPill(estado: _pedidoActivo!.estado),
            accion: 'Continuar entrega',
          ),
          const SizedBox(height: 16),
          // Tarjeta "Ver mis pedidos" SIEMPRE debajo del pedido activo
          _TarjetaVerPedidos(
            onTap: () => Navigator.of(context).pushNamed(HistorialPedidosScreen.routeName),
          ),
        ] else if (disponibilidad.disponible) ...[
          // Si no hay pedido activo y está disponible, mostrar "Ver mis pedidos"
          _TarjetaVerPedidos(
            onTap: () => Navigator.of(context).pushNamed(HistorialPedidosScreen.routeName),
          ),
        ] else ...[
          // Si no está disponible, mostrar mensaje
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Activá "Disponible" para empezar a recibir pedidos cerca tuyo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.teal),
            ),
          ),
        ],
      ],
    ];
  }
}

// ==================== WIDGETS DE DISEÑO ====================

// ENCABEZADO CON FOTO A LA IZQUIERDA
class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.saludo,
    required this.nombre,
    required this.fotoUrl,
    required this.modoEtiqueta,
  });

  final String saludo;
  final String? nombre;
  final String? fotoUrl;
  final String? modoEtiqueta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _Avatar(fotoUrl: fotoUrl, nombre: nombre),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(saludo, style: const TextStyle(color: AppColors.teal, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  nombre ?? 'Sesión activa',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (modoEtiqueta != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    modoEtiqueta!,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // HU-XX — selector de modo Paciente/Domiciliario para cuentas
          // con los 2 roles; el propio widget se oculta si la cuenta
          // tiene un solo rol (ver `BotonCambiarModo`).
          const BotonCambiarModo(),
        ],
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

// TARJETA DE ESTADÍSTICAS (Borde gris delgado)
class _TarjetaStats extends StatelessWidget {
  const _TarjetaStats({
    required this.icono,
    required this.valor,
    required this.label,
  });

  final IconData icono;
  final String valor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  icono,
                  color: AppColors.navy,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// TARJETA HERO PARA PACIENTE
class _TarjetaHeroBienvenida extends StatelessWidget {
  const _TarjetaHeroBienvenida({
    required this.titulo,
    required this.descripcion,
    required this.imagenAsset,
  });

  final String titulo;
  final String descripcion;
  final String imagenAsset;

  @override
  Widget build(BuildContext context) {
    // Antes esto era un Stack con el texto en un Padding a ancho completo
    // y la imagen `Positioned` encima a la derecha — en pantallas angostas
    // el texto no tenía ningún límite real que respetara el espacio de la
    // imagen y terminaba superpuesto. Con Row + Expanded, el texto nunca
    // puede invadir el ancho reservado a la imagen, sea cual sea el ancho
    // de pantalla.
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE3EFFD),
            Color(0xFFC0D9F5),
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'MediRuta',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    descripcion,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipOval(
              child: Image.asset(
                imagenAsset,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.skyBlue, width: 2),
                  ),
                  child: const Icon(Icons.local_shipping, color: AppColors.navy, size: 36),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TARJETA HERO PARA DOMICILIARIO (VERSIÓN 2 LÍNEAS)
class _TarjetaHeroBienvenidaDomiciliario extends StatelessWidget {
  const _TarjetaHeroBienvenidaDomiciliario();

  @override
  Widget build(BuildContext context) {
    // Mismo fix que `_TarjetaHeroBienvenida`: Row + Expanded en vez de
    // Stack + Positioned, para que el texto nunca invada el espacio de
    // la imagen en pantallas angostas.
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE3EFFD),
            Color(0xFFC0D9F5),
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'MediRuta - Domiciliario',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Lleva salud a tu comunidad',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Conecta con personas que necesitan sus medicamentos y realiza entregas seguras.',
                    style: TextStyle(
                      color: AppColors.navy.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipOval(
              child: Image.asset(
                'assets/images/domiciliario.png',
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.skyBlue, width: 2),
                  ),
                  child: const Icon(Icons.delivery_dining, color: AppColors.navy, size: 36),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TARJETA PARA PEDIR MEDICAMENTOS (PACIENTE)
class _TarjetaPedirMedicamentos extends StatelessWidget {
  const _TarjetaPedirMedicamentos({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.skyBlue.withValues(alpha: 0.3),
            ),
            child: const Icon(
              Icons.medication_outlined,
              color: AppColors.teal,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '¿Necesitás pedir tus medicamentos?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Realiza una nueva solicitud y te la llevamos a tu puerta.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Nueva solicitud',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// TARJETA PARA VER PEDIDOS (DOMICILIARIO)
class _TarjetaVerPedidos extends StatelessWidget {
  const _TarjetaVerPedidos({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.skyBlue.withValues(alpha: 0.3),
            ),
            child: const Icon(
              Icons.list_alt_outlined,
              color: AppColors.teal,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '¿Quieres ver tus pedidos?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Visualiza tus pedidos pendientes por entregar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Ver mis pedidos',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// TARJETA DE PEDIDO EN CURSO (Fondo súper claro y suave)
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
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5FAFF),
              Color(0xFFEAF3FC),
            ],
          ),
          border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.3)),
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
                      color: AppColors.navy,
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
                color: AppColors.navy,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  accion,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, color: AppColors.navy, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// TARJETA DE DISPONIBILIDAD (CON EL MISMO ESTILO QUE _TarjetaHero)
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
    return InkWell(
      onTap: () => onChanged(!disponible),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5FAFF),
              Color(0xFFEAF3FC),
            ],
          ),
          border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: disponible 
                    ? AppColors.teal.withValues(alpha: 0.15) 
                    : AppColors.skyBlue.withValues(alpha: 0.3),
              ),
              child: Icon(
                disponible ? Icons.bolt : Icons.bolt_outlined,
                color: disponible ? AppColors.teal : AppColors.navy,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    disponible ? 'Estás en línea' : 'Disponible para recibir pedidos',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    disponible 
                        ? 'Vas a aparecer en el pool de pedidos.' 
                        : 'Estás fuera de línea.',
                    style: TextStyle(
                      color: AppColors.navy.withValues(alpha: 0.6),
                      fontSize: 13,
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
                      color: AppColors.navy,
                    ),
                  )
                : Switch(
                    value: disponible,
                    onChanged: onChanged,
                    activeColor: AppColors.teal,
                    activeTrackColor: AppColors.teal.withValues(alpha: 0.4),
                    inactiveTrackColor: AppColors.skyBlue.withValues(alpha: 0.3),
                  ),
          ],
        ),
      ),
    );
  }
}