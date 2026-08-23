import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/usuario.dart';
import '../../domain/usecases/cerrar_sesion_usecase.dart';
import '../../domain/usecases/hay_sesion_guardada_usecase.dart';
import '../../domain/usecases/obtener_sesion_actual_usecase.dart';
import 'usuario_providers.dart';

/// Estado de sesión de la app — lo consume `AuthGate` en `main.dart` para
/// decidir entre pantalla de login o `home_screen`, y cualquier pantalla
/// que necesite el usuario autenticado.
sealed class AuthEstado {
  const AuthEstado();
}

class AuthCargando extends AuthEstado {
  const AuthCargando();
}

class AuthAutenticado extends AuthEstado {
  const AuthAutenticado(this.usuario);
  final Usuario usuario;
}

class AuthAnonimo extends AuthEstado {
  const AuthAnonimo();
}

class AuthSessionNotifier extends StateNotifier<AuthEstado> {
  AuthSessionNotifier({
    required HaySesionGuardadaUseCase haySesionGuardada,
    required ObtenerSesionActualUseCase obtenerSesionActual,
    required CerrarSesionUseCase cerrarSesion,
  }) : _haySesionGuardada = haySesionGuardada,
       _obtenerSesionActual = obtenerSesionActual,
       _cerrarSesion = cerrarSesion,
       super(const AuthCargando()) {
    _restaurar();
  }

  final HaySesionGuardadaUseCase _haySesionGuardada;
  final ObtenerSesionActualUseCase _obtenerSesionActual;
  final CerrarSesionUseCase _cerrarSesion;

  Future<void> _restaurar() async {
    final haySesion = await _haySesionGuardada.execute();
    if (!haySesion) {
      state = const AuthAnonimo();
      return;
    }

    try {
      final usuario = await _obtenerSesionActual.execute();
      state = AuthAutenticado(usuario);
    } catch (_) {
      // Sin sesión válida (tokens vencidos/revocados y el refresh
      // automático del ApiClient tampoco pudo renovarlos).
      state = const AuthAnonimo();
    }
  }

  /// Lo llaman `login_screen` y `registro_screen` (tras loguear) al
  /// terminar G03 con éxito.
  void sesionIniciada(Usuario usuario) {
    state = AuthAutenticado(usuario);
  }

  /// G07 — cierre de sesión desde `home_screen`.
  Future<void> cerrarSesion() async {
    try {
      await _cerrarSesion.execute();
    } catch (_) {
      // Los tokens locales ya se limpiaron en UsuarioRepositoryImpl aunque
      // la revocación remota falle (p. ej. sin conexión) — igual se saca
      // a la persona de la sesión local.
    }
    state = const AuthAnonimo();
  }
}

final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, AuthEstado>((ref) {
      return AuthSessionNotifier(
        haySesionGuardada: ref.watch(haySesionGuardadaUseCaseProvider),
        obtenerSesionActual: ref.watch(obtenerSesionActualUseCaseProvider),
        cerrarSesion: ref.watch(cerrarSesionUseCaseProvider),
      );
    });
