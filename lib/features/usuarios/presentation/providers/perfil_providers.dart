import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/perfil_remote_datasource.dart';
import '../../data/repositories/perfil_repository_impl.dart';
import '../../domain/repositories/perfil_repository.dart';
import '../../domain/usecases/actualizar_datos_comunes_usecase.dart';
import '../../domain/usecases/actualizar_disponibilidad_domiciliario_usecase.dart';
import '../../domain/usecases/actualizar_perfil_domiciliario_usecase.dart';
import '../../domain/usecases/actualizar_perfil_paciente_usecase.dart';
import '../../domain/usecases/desactivar_cuenta_usecase.dart';
import '../../domain/usecases/obtener_perfil_usecase.dart';
import '../../domain/usecases/subir_documento_domiciliario_usecase.dart';
import '../../domain/usecases/subir_foto_cedula_paciente_usecase.dart';
import '../../domain/usecases/subir_foto_perfil_usecase.dart';
import 'usuario_providers.dart';

/// Cableado de dependencias del perfil (HU-02) — mismo espíritu que
/// `usuario_providers.dart`. Reutiliza `apiClientProvider` ya existente
/// (mismo `ApiClient`, mismo manejo de tokens/refresh que auth).
final perfilRemoteDatasourceProvider = Provider<PerfilRemoteDatasource>((ref) {
  return PerfilRemoteDatasource(ref.watch(apiClientProvider));
});

final perfilRepositoryProvider = Provider<PerfilRepository>((ref) {
  return PerfilRepositoryImpl(ref.watch(perfilRemoteDatasourceProvider));
});

final obtenerPerfilUseCaseProvider = Provider(
  (ref) => ObtenerPerfilUseCase(ref.watch(perfilRepositoryProvider)),
);

final actualizarDatosComunesUseCaseProvider = Provider(
  (ref) => ActualizarDatosComunesUseCase(ref.watch(perfilRepositoryProvider)),
);

final actualizarPerfilPacienteUseCaseProvider = Provider(
  (ref) => ActualizarPerfilPacienteUseCase(ref.watch(perfilRepositoryProvider)),
);

final subirFotoCedulaPacienteUseCaseProvider = Provider(
  (ref) => SubirFotoCedulaPacienteUseCase(ref.watch(perfilRepositoryProvider)),
);

final subirFotoPerfilUseCaseProvider = Provider(
  (ref) => SubirFotoPerfilUseCase(ref.watch(perfilRepositoryProvider)),
);

final actualizarPerfilDomiciliarioUseCaseProvider = Provider(
  (ref) =>
      ActualizarPerfilDomiciliarioUseCase(ref.watch(perfilRepositoryProvider)),
);

final subirDocumentoDomiciliarioUseCaseProvider = Provider(
  (ref) => SubirDocumentoDomiciliarioUseCase(ref.watch(perfilRepositoryProvider)),
);

final desactivarCuentaUseCaseProvider = Provider(
  (ref) => DesactivarCuentaUseCase(ref.watch(perfilRepositoryProvider)),
);

final actualizarDisponibilidadDomiciliarioUseCaseProvider = Provider(
  (ref) => ActualizarDisponibilidadDomiciliarioUseCase(
    ref.watch(perfilRepositoryProvider),
  ),
);
