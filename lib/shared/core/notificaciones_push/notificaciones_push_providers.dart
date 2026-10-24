import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/notificaciones/presentation/notificaciones_provider.dart';
import 'notificaciones_push_service.dart';

/// Instancia única para toda la app — igual que `eventosSocketServiceProvider`,
/// la arranca/para el listener de `authSessionProvider` en `main.dart`
/// (ver `AuthGate`).
final Provider<NotificacionesPushService> notificacionesPushServiceProvider =
    Provider<NotificacionesPushService>((ref) {
      return NotificacionesPushService(ref.watch(notificacionesDatasourceProvider), ref);
    });
