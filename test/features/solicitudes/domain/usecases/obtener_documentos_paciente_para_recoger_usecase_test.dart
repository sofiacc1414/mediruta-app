import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/documentos_paciente_para_recoger.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/obtener_documentos_paciente_para_recoger_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('ObtenerDocumentosPacienteParaRecogerUseCase', () {
    test('devuelve los documentos que resuelve el repositorio', () async {
      const documentos = DocumentosPacienteParaRecoger(
        cedulaFrenteUrl: 'https://firmada.test/cedula_frente.jpg',
        cedulaReversoUrl: 'https://firmada.test/cedula_reverso.jpg',
      );
      final repo = FakeSolicitudRepository()
        ..documentosPacienteParaRecogerARetornar = documentos;
      final useCase = ObtenerDocumentosPacienteParaRecogerUseCase(repo);

      final resultado = await useCase.execute('solicitud-uuid');

      expect(resultado, documentos);
      expect(repo.ultimaLlamada, {
        'metodo': 'obtenerDocumentosPacienteParaRecoger',
        'solicitudId': 'solicitud-uuid',
      });
    });

    test('propaga el error si el pedido no está en la ventana permitida', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(
          statusCode: 404,
          message: 'Los documentos del paciente solo están disponibles mientras vas en camino a la farmacia.',
        );
      final useCase = ObtenerDocumentosPacienteParaRecogerUseCase(repo);

      expect(
        () => useCase.execute('solicitud-uuid'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
