import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/storage/shared_preferences_provider.dart';
import '../../../usuarios/presentation/providers/usuario_providers.dart';
import '../../data/datasources/borrador_local_datasource.dart';
import '../../data/datasources/solicitud_remote_datasource.dart';
import '../../data/repositories/borrador_local_repository_impl.dart';
import '../../data/repositories/solicitud_repository_impl.dart';
import '../../domain/repositories/borrador_local_repository.dart';
import '../../domain/repositories/solicitud_repository.dart';
import '../../domain/usecases/aceptar_pedido_usecase.dart';
import '../../domain/usecases/actualizar_solicitud_usecase.dart';
import '../../domain/usecases/cancelar_solicitud_usecase.dart';
import '../../domain/usecases/crear_solicitud_usecase.dart';
import '../../domain/usecases/entregar_pedido_usecase.dart';
import '../../domain/usecases/enviar_solicitud_usecase.dart';
import '../../domain/usecases/iniciar_entrega_usecase.dart';
import '../../domain/usecases/listar_pedidos_disponibles_usecase.dart';
import '../../domain/usecases/listar_solicitudes_usecase.dart';
import '../../domain/usecases/marcar_en_sitio_usecase.dart';
import '../../domain/usecases/marcar_medicamentos_recogidos_usecase.dart';
import '../../domain/usecases/obtener_solicitud_usecase.dart';
import '../../domain/usecases/reportar_novedad_usecase.dart';
import '../../domain/usecases/subir_receta_usecase.dart';

/// Cableado de dependencias de solicitudes (HU-03) — mismo espíritu que
/// `perfil_providers.dart`. Reutiliza `apiClientProvider` ya existente.
final solicitudRemoteDatasourceProvider = Provider<SolicitudRemoteDatasource>((ref) {
  return SolicitudRemoteDatasource(ref.watch(apiClientProvider));
});

final solicitudRepositoryProvider = Provider<SolicitudRepository>((ref) {
  return SolicitudRepositoryImpl(ref.watch(solicitudRemoteDatasourceProvider));
});

final crearSolicitudUseCaseProvider = Provider(
  (ref) => CrearSolicitudUseCase(ref.watch(solicitudRepositoryProvider)),
);

final listarSolicitudesUseCaseProvider = Provider(
  (ref) => ListarSolicitudesUseCase(ref.watch(solicitudRepositoryProvider)),
);

final obtenerSolicitudUseCaseProvider = Provider(
  (ref) => ObtenerSolicitudUseCase(ref.watch(solicitudRepositoryProvider)),
);

final actualizarSolicitudUseCaseProvider = Provider(
  (ref) => ActualizarSolicitudUseCase(ref.watch(solicitudRepositoryProvider)),
);

final subirRecetaUseCaseProvider = Provider(
  (ref) => SubirRecetaUseCase(ref.watch(solicitudRepositoryProvider)),
);

final enviarSolicitudUseCaseProvider = Provider(
  (ref) => EnviarSolicitudUseCase(ref.watch(solicitudRepositoryProvider)),
);

final cancelarSolicitudUseCaseProvider = Provider(
  (ref) => CancelarSolicitudUseCase(ref.watch(solicitudRepositoryProvider)),
);

// --- Domiciliario (HU-09/HU-07) ---

final listarPedidosDisponiblesUseCaseProvider = Provider(
  (ref) => ListarPedidosDisponiblesUseCase(ref.watch(solicitudRepositoryProvider)),
);

final aceptarPedidoUseCaseProvider = Provider(
  (ref) => AceptarPedidoUseCase(ref.watch(solicitudRepositoryProvider)),
);

final marcarMedicamentosRecogidosUseCaseProvider = Provider(
  (ref) => MarcarMedicamentosRecogidosUseCase(ref.watch(solicitudRepositoryProvider)),
);

final iniciarEntregaUseCaseProvider = Provider(
  (ref) => IniciarEntregaUseCase(ref.watch(solicitudRepositoryProvider)),
);

final marcarEnSitioUseCaseProvider = Provider(
  (ref) => MarcarEnSitioUseCase(ref.watch(solicitudRepositoryProvider)),
);

final entregarPedidoUseCaseProvider = Provider(
  (ref) => EntregarPedidoUseCase(ref.watch(solicitudRepositoryProvider)),
);

final reportarNovedadUseCaseProvider = Provider(
  (ref) => ReportarNovedadUseCase(ref.watch(solicitudRepositoryProvider)),
);

/// El borrador local no pasa por casos de uso propios (guardar/leer/
/// limpiar son pura persistencia de dispositivo, sin lógica de negocio
/// que validar ni errores de dominio que traducir) — las pantallas usan
/// este repositorio directamente.
final borradorLocalDatasourceProvider = Provider<BorradorLocalDatasource>((ref) {
  return BorradorLocalDatasource(ref.watch(sharedPreferencesProvider));
});

final borradorLocalRepositoryProvider = Provider<BorradorLocalRepository>((ref) {
  return BorradorLocalRepositoryImpl(ref.watch(borradorLocalDatasourceProvider));
});
