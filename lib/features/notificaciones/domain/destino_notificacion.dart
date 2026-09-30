/// A dónde lleva un toque, según el tipo y el modo activo.
/// El permiso real lo confirma la API al abrir el pedido.
enum DestinoNotificacion { detallePedido, pedidoAsignado, perfil, chatPedido, sinPermiso }

DestinoNotificacion destinoNotificacion({
  required String tipo,
  required String? modo,
}) {
  if (tipo == 'cambio_estado' && modo == 'PACIENTE') {
    return DestinoNotificacion.detallePedido;
  }
  if (tipo == 'asignacion' && modo == 'DOMICILIARIO') {
    return DestinoNotificacion.pedidoAsignado;
  }
  if (tipo == 'validacion_cuenta' && modo == 'DOMICILIARIO') {
    return DestinoNotificacion.perfil;
  }
  // Mensaje de chat — ambos roles pueden recibirlo (la API ya valida que
  // sea paciente o domiciliario del pedido al abrir `ChatScreen`).
  if (tipo == 'mensaje_chat' && (modo == 'PACIENTE' || modo == 'DOMICILIARIO')) {
    return DestinoNotificacion.chatPedido;
  }
  return DestinoNotificacion.sinPermiso;
}
