import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../usuarios/presentation/providers/usuario_providers.dart';
import '../data/chat_remote_datasource.dart';

final chatDatasourceProvider = Provider(
  (ref) => ChatRemoteDatasource(ref.watch(apiClientProvider)),
);
