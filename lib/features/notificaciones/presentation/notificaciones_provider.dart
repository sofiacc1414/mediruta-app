import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../usuarios/presentation/providers/usuario_providers.dart';
import '../data/notificaciones_remote_datasource.dart';

final notificacionesDatasourceProvider = Provider(
  (ref) => NotificacionesRemoteDatasource(ref.watch(apiClientProvider)),
);
