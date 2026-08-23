import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/solicitudes/presentation/screens/mis_solicitudes_screen.dart';
import 'features/solicitudes/presentation/screens/nueva_solicitud_screen.dart';
import 'features/solicitudes/presentation/screens/solicitud_detalle_screen.dart';
import 'features/usuarios/presentation/providers/auth_session_provider.dart';
import 'features/usuarios/presentation/screens/cambiar_contrasena_screen.dart';
import 'features/usuarios/presentation/screens/home_screen.dart';
import 'features/usuarios/presentation/screens/login_screen.dart';
import 'features/usuarios/presentation/screens/onboarding_screen.dart';
import 'features/usuarios/presentation/screens/perfil_screen.dart';
import 'features/usuarios/presentation/screens/recuperar_contrasena_screen.dart';
import 'features/usuarios/presentation/screens/registro_screen.dart';
import 'features/usuarios/presentation/screens/restablecer_contrasena_screen.dart';
import 'shared/core/storage/shared_preferences_provider.dart';
import 'shared/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MediRutaApp(),
    ),
  );
}

class MediRutaApp extends StatelessWidget {
  const MediRutaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediRuta',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegistroScreen.routeName: (_) => const RegistroScreen(),
        RecuperarContrasenaScreen.routeName: (_) => const RecuperarContrasenaScreen(),
        CambiarContrasenaScreen.routeName: (_) => const CambiarContrasenaScreen(),
        PerfilScreen.routeName: (_) => const PerfilScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        MisSolicitudesScreen.routeName: (_) => const MisSolicitudesScreen(),
        NuevaSolicitudScreen.routeName: (_) => const NuevaSolicitudScreen(),
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
