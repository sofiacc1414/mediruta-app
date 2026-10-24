import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/core/network/api_exception.dart';
import '../../calificaciones/presentation/screens/calificacion_form_screen.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../solicitudes/presentation/providers/solicitud_providers.dart';
import '../../solicitudes/presentation/screens/mi_pedido_activo_screen.dart';
import '../../solicitudes/presentation/screens/pedido_completado_screen.dart';
import '../../solicitudes/presentation/screens/solicitud_detalle_screen.dart';
import '../../usuarios/domain/entities/rol_asignado.dart';
import '../../usuarios/presentation/providers/auth_session_provider.dart';
import '../../usuarios/presentation/screens/perfil_screen.dart';
import '../domain/destino_notificacion.dart';

/// `Ref` y `WidgetRef` no comparten un tipo común en esta versión de
/// Riverpod (`WidgetRef` no extiende `Ref`), pero sí tienen el mismo
/// `read<T>(ProviderListenable<T>)` — alcanza con tomar ese método como
/// parámetro para que esta función sirva desde un widget (`ref.read`) o
/// desde un servicio plano que solo tiene un `Ref` (`_ref.read`).
typedef LectorProvider = T Function<T>(ProviderListenable<T> provider);

/// Modo activo de la cuenta (rol con el que se está usando la app ahora),
/// el mismo que usa `destinoNotificacion` para decidir a dónde navegar.
/// Compartido entre `NotificacionesScreen` y `NotificacionesPushService`
/// para que un push toque exactamente la misma pantalla que su
/// equivalente en la lista interna.
String? modoActivoActual(LectorProvider read) {
  final estado = read(authSessionProvider);
  final usuario = estado is AuthAutenticado ? estado.usuario : null;
  final roles = usuario?.roles ?? const <RolAsignado>[];
  return read(modoActivoProvider) ?? (roles.isNotEmpty ? roles.first.codigo : null);
}

/// Navega al destino real de una notificación (tipo + referenciaId),
/// igual que hace `NotificacionesScreen._abrir` al tocar un ítem de la
/// lista. La usa también `NotificacionesPushService` al tocar un push,
/// para que ya no haga falta caer siempre en la lista genérica.
Future<void> navegarNotificacion(
  BuildContext context,
  LectorProvider read, {
  required String tipo,
  required String? referenciaId,
}) async {
  final destino = destinoNotificacion(tipo: tipo, modo: modoActivoActual(read));
  switch (destino) {
    case DestinoNotificacion.detallePedido:
      if (referenciaId == null) return;
      await Navigator.pushNamed(context, SolicitudDetalleScreen.routeName, arguments: referenciaId);
    case DestinoNotificacion.pedidoAsignado:
      await _abrirPedidoDomiciliario(context, read, referenciaId);
    case DestinoNotificacion.perfil:
      await read(authSessionProvider.notifier).refrescarIdentidad();
      if (!context.mounted) return;
      await Navigator.pushNamed(context, PerfilScreen.routeName);
    case DestinoNotificacion.chatPedido:
      if (referenciaId == null) return;
      await Navigator.pushNamed(context, ChatScreen.routeName, arguments: referenciaId);
    case DestinoNotificacion.calificarPedido:
      await _abrirCalificacion(context, read, referenciaId);
    case DestinoNotificacion.sinPermiso:
      _mostrarSnackBarSiHayScaffold(
        context,
        'No puedes abrir esta información.',
      );
  }
}

Future<void> _abrirPedidoDomiciliario(BuildContext context, LectorProvider read, String? id) async {
  if (id == null) return;
  try {
    final pedido = await read(obtenerPedidoDomiciliarioUseCaseProvider).execute(id);
    if (!context.mounted) return;
    final cerrado = pedido.estado == 'entregado' || pedido.estado == 'cancelada';
    if (cerrado) {
      await Navigator.pushNamed(context, PedidoCompletadoScreen.routeName, arguments: id);
    } else {
      await Navigator.pushNamed(context, MiPedidoActivoScreen.routeName);
    }
  } on ApiException {
    if (!context.mounted) return;
    _mostrarSnackBarSiHayScaffold(context, 'No puedes ver este pedido.');
  }
}

Future<void> _abrirCalificacion(BuildContext context, LectorProvider read, String? id) async {
  if (id == null) return;
  try {
    final solicitud = await read(obtenerSolicitudUseCaseProvider).execute(id);
    if (!context.mounted) return;
    await Navigator.pushNamed(
      context,
      CalificacionFormScreen.routeName,
      arguments: CalificacionFormArgs(
        pedidoId: id,
        codigoPedido: solicitud.codigoPedido,
        estadoPedido: solicitud.estado,
        editar: false,
      ),
    );
  } on ApiException {
    if (!context.mounted) return;
    _mostrarSnackBarSiHayScaffold(context, 'No puedes calificar este pedido.');
  }
}

/// Al navegar desde el push, el `context` viene de `appNavigatorKey` y
/// puede no tener todavía un `Scaffold`/`ScaffoldMessenger` ancestro en
/// la ruta recién empujada — evita tumbar la navegación por un aviso
/// que no es crítico.
void _mostrarSnackBarSiHayScaffold(BuildContext context, String mensaje) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.showSnackBar(SnackBar(content: Text(mensaje)));
}
