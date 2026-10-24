/// Módulo 3 — billetera del Domiciliario (acumulado histórico).
///
/// `saldoCobrado` es lo que el Domiciliario YA tiene en mano: ganancia
/// neta de pedidos en efectivo (siempre en su bolsillo de inmediato,
/// aparte de lo que debe devolver como `deudaEfectivo`) + lo que ya le
/// liquidó el admin de tarjeta/transferencia.
///
/// `saldoPendienteCobrar` es tarjeta/transferencia que la EMPRESA ya
/// cobró pero todavía no le pagó al Domiciliario — es plata que la
/// empresa le debe, no plata que él ya tiene.
///
/// `deudaEfectivo` es lo que el Domiciliario le debe a la empresa por
/// haber cobrado en efectivo. Si `bloqueadoPorTope` es `true`, no puede
/// aceptar pedidos nuevos hasta que el admin confirme que la liquidó.
class WalletDomiciliario {
  const WalletDomiciliario({
    required this.comisionAcumulada,
    required this.saldoCobrado,
    required this.saldoPendienteCobrar,
    required this.deudaEfectivo,
    required this.bloqueadoPorTope,
    required this.topeRecaudoEfectivo,
  });

  final double comisionAcumulada;
  final double saldoCobrado;
  final double saldoPendienteCobrar;
  final double deudaEfectivo;
  final bool bloqueadoPorTope;
  final double topeRecaudoEfectivo;

  factory WalletDomiciliario.fromJson(Map<String, dynamic> json) {
    return WalletDomiciliario(
      comisionAcumulada: (json['comisionAcumulada'] as num).toDouble(),
      saldoCobrado: (json['saldoCobrado'] as num).toDouble(),
      saldoPendienteCobrar: (json['saldoPendienteCobrar'] as num).toDouble(),
      deudaEfectivo: (json['deudaEfectivo'] as num).toDouble(),
      bloqueadoPorTope: json['bloqueadoPorTope'] as bool,
      topeRecaudoEfectivo: (json['topeRecaudoEfectivo'] as num).toDouble(),
    );
  }
}

/// Balance recalculado para un rango de fechas puntual — no es el
/// acumulado histórico de arriba. "Balance" es el neto ganado por
/// entregas de ambos métodos en ese rango, sin importar si ya se
/// liquidó.
class WalletDomiciliarioPeriodo {
  const WalletDomiciliarioPeriodo({
    required this.cobradoEfectivoPeriodo,
    required this.pendienteTarjetaTransferenciaPeriodo,
    required this.deudaGeneradaEfectivoPeriodo,
    required this.liquidadoEnPeriodo,
    required this.balancePeriodo,
  });

  final double cobradoEfectivoPeriodo;
  final double pendienteTarjetaTransferenciaPeriodo;
  final double deudaGeneradaEfectivoPeriodo;
  final double liquidadoEnPeriodo;
  final double balancePeriodo;

  factory WalletDomiciliarioPeriodo.fromJson(Map<String, dynamic> json) {
    return WalletDomiciliarioPeriodo(
      cobradoEfectivoPeriodo: (json['cobradoEfectivoPeriodo'] as num).toDouble(),
      pendienteTarjetaTransferenciaPeriodo:
          (json['pendienteTarjetaTransferenciaPeriodo'] as num).toDouble(),
      deudaGeneradaEfectivoPeriodo:
          (json['deudaGeneradaEfectivoPeriodo'] as num).toDouble(),
      liquidadoEnPeriodo: (json['liquidadoEnPeriodo'] as num).toDouble(),
      balancePeriodo: (json['balancePeriodo'] as num).toDouble(),
    );
  }
}
