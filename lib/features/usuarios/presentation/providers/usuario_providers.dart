import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/config/app_config.dart';
import '../../../../shared/core/network/api_client.dart';
import '../../data/datasources/usuario_remote_datasource.dart';
import '../../data/repositories/usuario_repository_impl.dart';
import '../../domain/repositories/usuario_repository.dart';
import '../../domain/usecases/cambiar_contrasena_usecase.dart';
import '../../domain/usecases/cerrar_sesion_usecase.dart';
import '../../domain/usecases/hay_sesion_guardada_usecase.dart';
import '../../domain/usecases/iniciar_sesion_usecase.dart';
import '../../domain/usecases/obtener_sesion_actual_usecase.dart';
import '../../domain/usecases/refrescar_sesion_usecase.dart';
import '../../domain/usecases/registrar_usuario_usecase.dart';
import '../../domain/usecases/restablecer_contrasena_usecase.dart';
import '../../domain/usecases/solicitar_recuperacion_contrasena_usecase.dart';

/// Cableado de dependencias del feature `usuarios` (DOCS/context.md, Parte
/// B, sección 11 — providers de Riverpod).
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(baseUrl: AppConfig.apiBaseUrl);
  ref.onDispose(client.close);
  return client;
});

final Provider<UsuarioRemoteDatasource> usuarioRemoteDatasourceProvider =
    Provider<UsuarioRemoteDatasource>((ref) {
      return UsuarioRemoteDatasource(ref.watch(apiClientProvider));
    });

final Provider<UsuarioRepository> usuarioRepositoryProvider = Provider<UsuarioRepository>((
  ref,
) {
  return UsuarioRepositoryImpl(
    ref.watch(usuarioRemoteDatasourceProvider),
    ref.watch(apiClientProvider),
  );
});

final registrarUsuarioUseCaseProvider = Provider(
  (ref) => RegistrarUsuarioUseCase(ref.watch(usuarioRepositoryProvider)),
);

final iniciarSesionUseCaseProvider = Provider(
  (ref) => IniciarSesionUseCase(ref.watch(usuarioRepositoryProvider)),
);

final obtenerSesionActualUseCaseProvider = Provider(
  (ref) => ObtenerSesionActualUseCase(ref.watch(usuarioRepositoryProvider)),
);

final Provider<RefrescarSesionUseCase> refrescarSesionUseCaseProvider =
    Provider<RefrescarSesionUseCase>(
      (ref) => RefrescarSesionUseCase(ref.watch(usuarioRepositoryProvider)),
    );

final cerrarSesionUseCaseProvider = Provider(
  (ref) => CerrarSesionUseCase(ref.watch(usuarioRepositoryProvider)),
);

final solicitarRecuperacionContrasenaUseCaseProvider = Provider(
  (ref) => SolicitarRecuperacionContrasenaUseCase(ref.watch(usuarioRepositoryProvider)),
);

final restablecerContrasenaUseCaseProvider = Provider(
  (ref) => RestablecerContrasenaUseCase(ref.watch(usuarioRepositoryProvider)),
);

final cambiarContrasenaUseCaseProvider = Provider(
  (ref) => CambiarContrasenaUseCase(ref.watch(usuarioRepositoryProvider)),
);

final haySesionGuardadaUseCaseProvider = Provider(
  (ref) => HaySesionGuardadaUseCase(ref.watch(usuarioRepositoryProvider)),
);

/// Conecta `ApiClient.onSesionExpirada` con `RefrescarSesionUseCase` — un
/// provider intermedio, distinto de `apiClientProvider`, a propósito: si la
/// asignación viviera dentro del `build` de `apiClientProvider` mismo, su
/// `ref.read(refrescarSesionUseCaseProvider)` formaría un ciclo real en el
/// grafo (`refrescarSesionUseCaseProvider` depende de
/// `usuarioRepositoryProvider`, que depende de `apiClientProvider`), y
/// Riverpod lo detecta incluso con `ref.read` (no solo `ref.watch`) porque
/// ya quedaría registrada la dependencia inversa. Este provider en cambio
/// depende de ambos sin que ninguno dependa de él, así que no es
/// autorreferencial. Alguien debe `watch`earlo una vez al arrancar la app
/// para que el `build` corra — lo hace `authSessionProvider`.
final Provider<void> apiClientRefreshWiringProvider = Provider<void>((ref) {
  final client = ref.watch(apiClientProvider);
  client.onSesionExpirada = () => ref.read(refrescarSesionUseCaseProvider).execute();
});
