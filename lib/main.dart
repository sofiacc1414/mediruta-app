import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/calificaciones/presentation/screens/calificacion_confirmacion_screen.dart';
import 'features/calificaciones/presentation/screens/calificacion_form_screen.dart';
import 'features/calificaciones/presentation/screens/pedidos_calificacion_screen.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/chatbot/presentation/chatbot_screen.dart';
import 'features/solicitudes/presentation/screens/historial_pedidos_screen.dart';
import 'features/solicitudes/presentation/screens/mi_pedido_activo_screen.dart';
import 'features/solicitudes/presentation/screens/mis_solicitudes_screen.dart';
import 'features/solicitudes/presentation/screens/nueva_solicitud_screen.dart';
import 'features/solicitudes/presentation/screens/pedido_completado_screen.dart';
import 'features/solicitudes/presentation/screens/pedidos_disponibles_screen.dart';
import 'features/solicitudes/presentation/screens/solicitud_detalle_screen.dart';
import 'features/tracking/presentation/seguimiento_mapa_screen.dart';
import 'features/wallet/presentation/screens/wallet_screen.dart';
import 'features/usuarios/presentation/providers/auth_session_provider.dart';
import 'features/usuarios/presentation/screens/cambiar_contrasena_screen.dart';
import 'features/notificaciones/presentation/notificaciones_screen.dart';
import 'features/usuarios/presentation/screens/home_screen.dart';
import 'features/usuarios/presentation/screens/login_screen.dart';
import 'features/usuarios/presentation/screens/onboarding_screen.dart';
import 'features/usuarios/presentation/screens/perfil_screen.dart';
import 'features/usuarios/presentation/screens/recuperar_contrasena_screen.dart';
import 'features/usuarios/presentation/screens/registro_screen.dart';
import 'features/usuarios/presentation/screens/restablecer_contrasena_screen.dart';
import 'shared/core/navigation/app_navigator_key.dart';
import 'shared/core/notificaciones_push/notificaciones_push_providers.dart';
import 'shared/core/storage/shared_preferences_provider.dart';
import 'shared/core/theme/app_colors.dart';
import 'shared/core/theme/app_theme.dart';
import 'shared/core/theme/modo_adulto_mayor_provider.dart';
import 'shared/core/theme/modo_alto_contraste_provider.dart';
import 'shared/core/theme/modo_oscuro_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (error) {
    // Sin `google-services.json` (todavía no lo subió el dueño del
    // proyecto) o cualquier otro fallo de configuración de Firebase, la
    // app tiene que poder arrancar igual — push queda simplemente
    // desactivado (`NotificacionesPushService.iniciarSesion` también
    // está en try/catch por si falla algo más adelante).
    debugPrint('Firebase.initializeApp falló: $error');
  }
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MediRutaApp(),
    ),
  );
}

class MediRutaApp extends ConsumerWidget {
  const MediRutaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modoAdultoMayor = ref.watch(modoAdultoMayorProvider);
    final modoOscuro = ref.watch(modoOscuroProvider);
    final altoContraste = ref.watch(modoAltoContrasteProvider);
    // `AppColors` no tiene acceso a `ref` (lo usan pantallas/widgets sin
    // BuildContext) — se configura acá, una sola vez por rebuild de la
    // raíz, antes de construir nada que lo lea. Cada pantalla de nivel
    // superior hace `ref.watch(modoOscuroProvider)`/
    // `ref.watch(modoAltoContrasteProvider)` (ver `PerfilScreen` y el
    // resto) para que Riverpod la reconstruya cuando cambian — sin eso,
    // una pantalla ya montada no se repintaría sola al togglear acá.
    AppColors.configurar(oscuro: modoOscuro, altoContraste: altoContraste);
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'MediRuta',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // "Modo adulto mayor" (Perfil) — antes el switch no hacía nada.
      // Se aplica acá, en la raíz, para que agrande la letra en TODA
      // la app (no solo en la pantalla donde se activa).
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(modoAdultoMayor ? escalaTextoAdultoMayor : 1.0),
        ),
        child: child!,
      ),
      home: const AuthGate(),
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegistroScreen.routeName: (_) => const RegistroScreen(),
        RecuperarContrasenaScreen.routeName: (_) => const RecuperarContrasenaScreen(),
        CambiarContrasenaScreen.routeName: (_) => const CambiarContrasenaScreen(),
        PerfilScreen.routeName: (_) => const PerfilScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        NotificacionesScreen.routeName: (_) => const NotificacionesScreen(),
        ChatbotScreen.routeName: (_) => const ChatbotScreen(),
        MisSolicitudesScreen.routeName: (_) => const MisSolicitudesScreen(),
        PedidosCalificacionScreen.routeName: (_) => const PedidosCalificacionScreen(),
        NuevaSolicitudScreen.routeName: (_) => const NuevaSolicitudScreen(),
        PedidosDisponiblesScreen.routeName: (_) => const PedidosDisponiblesScreen(),
        MiPedidoActivoScreen.routeName: (_) => const MiPedidoActivoScreen(),
        HistorialPedidosScreen.routeName: (_) => const HistorialPedidosScreen(),
        WalletScreen.routeName: (_) => const WalletScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == RestablecerContrasenaScreen.routeName) {
          final correo = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => RestablecerContrasenaScreen(correo: correo),
          );
        }
        if (settings.name == SolicitudDetalleScreen.routeName) {
          final solicitudId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => SolicitudDetalleScreen(solicitudId: solicitudId),
          );
        }
        if (settings.name == CalificacionFormScreen.routeName) {
          final args = settings.arguments as CalificacionFormArgs;
          return MaterialPageRoute(
            builder: (_) => CalificacionFormScreen(args: args),
          );
        }
        if (settings.name == CalificacionConfirmacionScreen.routeName) {
          final pedidoId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => CalificacionConfirmacionScreen(pedidoId: pedidoId),
          );
        }
        if (settings.name == PedidoCompletadoScreen.routeName) {
          final solicitudId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => PedidoCompletadoScreen(solicitudId: solicitudId),
          );
        }
        if (settings.name == SeguimientoMapaScreen.routeName) {
          final solicitudId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => SeguimientoMapaScreen(solicitudId: solicitudId),
          );
        }
        if (settings.name == ChatScreen.routeName) {
          final solicitudId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => ChatScreen(solicitudId: solicitudId),
          );
        }
        return null;
      },
    );
  }
}

/// Decide entre onboarding, login y home según `authSessionProvider` — es
/// lo primero que se muestra al abrir la app (DOCS/context.md, sección 12:
/// sesión persistente vía `flutter_secure_storage` + `GET /auth/me`). El
/// onboarding no es parte de ningún criterio Gxx de HU-01 — se agregó a
/// pedido explícito y se muestra una vez por apertura de la app (no
/// persiste entre reinicios, ver onboarding_screen.dart).
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _onboardingVista = false;

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(authSessionProvider);

    // Push (FCM) necesita sesión para registrar el token
    // (`/notificaciones/dispositivo` requiere auth) — se arranca acá,
    // recién cuando el estado pasa a autenticado (login, registro o
    // sesión restaurada al abrir la app), y se para al cerrar sesión.
    // `AuthGate` vive durante toda la vida de la app (es el `home` del
    // `MaterialApp`), así que este listener no se pierde entre medio.
    ref.listen<AuthEstado>(authSessionProvider, (previous, next) {
      final servicio = ref.read(notificacionesPushServiceProvider);
      if (next is AuthAutenticado) {
        unawaited(servicio.iniciarSesion());
      } else if (next is AuthAnonimo) {
        unawaited(servicio.detenerSesion());
      }
    });

    return switch (estado) {
      AuthCargando() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthAnonimo() when !_onboardingVista => OnboardingScreen(
        onComenzar: () => setState(() => _onboardingVista = true),
      ),
      AuthAnonimo() => const LoginScreen(),
      AuthAutenticado() => const HomeScreen(),
    };
  }
}
