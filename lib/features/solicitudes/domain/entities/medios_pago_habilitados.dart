/// Módulo 4 — qué medios de pago puede elegir el Paciente ahora mismo
/// (toggles del panel admin). Si un medio está deshabilitado mientras
/// el Paciente estaba armando el pedido con ese medio ya elegido, el
/// envío falla con un mensaje claro (ver `ApiException` de
/// `MedioPagoNoHabilitadoError` del lado de la API).
class MediosPagoHabilitados {
  const MediosPagoHabilitados({
    required this.pagoEfectivoHabilitado,
    required this.pagoTarjetaHabilitado,
    required this.pagoTransferenciaHabilitado,
  });

  final bool pagoEfectivoHabilitado;
  final bool pagoTarjetaHabilitado;
  final bool pagoTransferenciaHabilitado;

  factory MediosPagoHabilitados.fromJson(Map<String, dynamic> json) {
    return MediosPagoHabilitados(
      pagoEfectivoHabilitado: json['pagoEfectivoHabilitado'] as bool,
      pagoTarjetaHabilitado: json['pagoTarjetaHabilitado'] as bool,
      pagoTransferenciaHabilitado: json['pagoTransferenciaHabilitado'] as bool,
    );
  }
}
