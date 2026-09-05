import '../repositories/solicitud_repository.dart';

/// HU-07 (ronda 3) — el Paciente reporta que el código de entrega no se
/// generó o no lo ve en su pantalla. El admin lo regenera o lo reenvía
/// por correo directo sobre el pedido — nada que aprobar acá.
class ReportarCodigoNoGeneradoUseCase {
  const ReportarCodigoNoGeneradoUseCase(this._repository);

  final SolicitudRepository _repository;

  Future<void> execute(String solicitudId, {String? detalle}) {
    return _repository.reportarCodigoNoGenerado(solicitudId, detalle: detalle);
  }
}
