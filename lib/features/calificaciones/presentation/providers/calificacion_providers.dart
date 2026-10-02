import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../usuarios/presentation/providers/usuario_providers.dart';
import '../../data/datasources/calificacion_remote_datasource.dart';
import '../../data/repositories/calificacion_repository_impl.dart';
import '../../domain/repositories/calificacion_repository.dart';
import '../../domain/usecases/actualizar_calificacion_usecase.dart';
import '../../domain/usecases/consultar_calificacion_usecase.dart';
import '../../domain/usecases/crear_calificacion_usecase.dart';
import '../../domain/usecases/listar_pedidos_calificacion_usecase.dart';
import '../../domain/usecases/retirar_calificacion_usecase.dart';

final calificacionRepositoryProvider = Provider<CalificacionRepository>((ref) {
  return CalificacionRepositoryImpl(
    CalificacionRemoteDatasource(ref.watch(apiClientProvider)),
  );
});

final listarPedidosCalificacionUseCaseProvider = Provider(
  (ref) => ListarPedidosCalificacionUseCase(ref.watch(calificacionRepositoryProvider)),
);

final consultarCalificacionUseCaseProvider = Provider(
  (ref) => ConsultarCalificacionUseCase(ref.watch(calificacionRepositoryProvider)),
);

final crearCalificacionUseCaseProvider = Provider(
  (ref) => CrearCalificacionUseCase(ref.watch(calificacionRepositoryProvider)),
);

final actualizarCalificacionUseCaseProvider = Provider(
  (ref) => ActualizarCalificacionUseCase(ref.watch(calificacionRepositoryProvider)),
);

final retirarCalificacionUseCaseProvider = Provider(
  (ref) => RetirarCalificacionUseCase(ref.watch(calificacionRepositoryProvider)),
);
