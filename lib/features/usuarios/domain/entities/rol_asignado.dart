/// Un rol asignado a un usuario y su estado de asignación (`habilitado`,
/// `pendiente_validacion`, `rechazado`) — distinto del `estadoCuenta` del
/// usuario (DOCS/context.md, Parte B, sección 4.1, modelo multirrol).
class RolAsignado {
  const RolAsignado({required this.codigo, required this.estado});

  final String codigo;
  final String estado;

  factory RolAsignado.fromJson(Map<String, dynamic> json) {
    return RolAsignado(
      codigo: json['codigo'] as String,
      estado: json['estado'] as String,
    );
  }
}
