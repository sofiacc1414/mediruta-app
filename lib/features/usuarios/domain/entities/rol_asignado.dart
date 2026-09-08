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

/// `estadoDe('DOMICILIARIO')` — el estado de asignación de ese rol
/// (`habilitado`/`pendiente_validacion`/`rechazado`), o `null` si la
/// cuenta ni siquiera lo tiene. Se usa en cualquier pantalla que exige
/// el rol habilitado (el `RolesGuard` de la API lo exige igual) para
/// avisar "en proceso de validación" en vez de dejar que la llamada
/// falle con un error de rol confuso.
extension RolesAsignadosEstado on List<RolAsignado> {
  String? estadoDe(String codigo) {
    final rol = where((r) => r.codigo == codigo);
    return rol.isEmpty ? null : rol.first.estado;
  }
}
