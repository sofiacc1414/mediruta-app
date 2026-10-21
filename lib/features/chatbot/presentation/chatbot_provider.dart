import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../usuarios/presentation/providers/usuario_providers.dart';
import '../data/chatbot_remote_datasource.dart';

final chatbotDatasourceProvider = Provider(
  (ref) => ChatbotRemoteDatasource(ref.watch(apiClientProvider)),
);
