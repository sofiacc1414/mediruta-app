import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/usuarios/presentation/providers/auth_session_provider.dart';
import 'features/usuarios/presentation/screens/cambiar_contrasena_screen.dart';
import 'features/usuarios/presentation/screens/home_screen.dart';
import 'features/usuarios/presentation/screens/login_screen.dart';
import 'features/usuarios/presentation/screens/recuperar_contrasena_screen.dart';
import 'features/usuarios/presentation/screens/registro_screen.dart';
import 'features/usuarios/presentation/screens/restablecer_contrasena_screen.dart';
import 'shared/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MediRutaApp()));
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
        HomeScreen.routeName: (_) => const HomeScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == RestablecerContrasenaScreen.routeName) {
          final correo = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => RestablecerContrasenaScreen(correo: correo),
          );
        }
        return null;
      },
    );
  }
}

/// Decide entre login y home según `authSessionProvider` — es lo primero
/// que se muestra al abrir la app (DOCS/context.md, sección 12: sesión
/// persistente vía `flutter_secure_storage` + `GET /auth/me`).
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(authSessionProvider);

    return switch (estado) {
      AuthCargando() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthAnonimo() => const LoginScreen(),
      AuthAutenticado() => const HomeScreen(),
    };
  }
}
