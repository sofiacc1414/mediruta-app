/// HU-07 (ronda 5) — "mis reportes sobre este pedido", con su estado.
/// A diferencia de [Solicitud.novedadAbierta] (solo la última sin
/// resolver), esto trae todas — resueltas incluidas — para que el
/// Paciente vea el resultado de las que ya se atendieron. Ver
/// `ListarNovedadesSolicitudUseCase`.
class NovedadResumen {
  const NovedadResumen({
    required this.id,
    required this.tipo,
    required this.detalle,
    required this.origen,
    required this.creadoEn,
    required this.resuelta,
    required this.accionEdicion,
    required this.datosPropuestos,
  });

  final String id;

  /// 'pregunta' | 'edicion' | 'codigo'.
  final String tipo;
  final String detalle;

  /// 'paciente' | 'domiciliario'.
  final String origen;
  final String creadoEn;
  final bool resuelta;

  /// 'aprobada' | 'rechazada' | null (null si no es tipo 'edicion', o
  /// todavía no se resolvió).
  final String? accionEdicion;

  /// Solo para `tipo == 'edicion'` — se usa para saber si la
  /// corrección pedida incluía medicamentos y/o una foto de receta
  /// nueva (no solo direcciones), y así decidir si mostrar el aviso de
  /// "cancelá el pedido y creá uno nuevo" cuando se rechaza.
  final Map<String, dynamic>? datosPropuestos;

  bool get incluyeMedicamentosOReceta =>
      datosPropuestos != null &&
      (datosPropuestos!['medicamentos'] != null || datosPropuestos!['recetaPath'] != null);

  factory NovedadResumen.fromJson(Map<String, dynamic> json) {
    return NovedadResumen(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      detalle: json['detalle'] as String,
      origen: json['origen'] as String,
      creadoEn: json['creadoEn'] as String,
      resuelta: json['resuelta'] as bool,
      accionEdicion: json['accionEdicion'] as String?,
      datosPropuestos: json['datosPropuestos'] as Map<String, dynamic>?,
    );
  }
}
