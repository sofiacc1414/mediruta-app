/// A dónde lleva un toque, según el tipo y el modo activo.
/// El permiso real lo confirma la API al abrir el pedido.
enum DestinoNotificacion { detallePedido, pedidoAsignado, perfil, sinPermiso }

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
  return DestinoNotificacion.sinPermiso;
}
