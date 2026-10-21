import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/formula_extraida.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/medicamento.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/extraer_datos_formula_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('ExtraerDatosFormulaUseCase', () {
    test('delega bytes, nombre y content type, y devuelve lo que trae el repo', () async {
      final repo = FakeSolicitudRepository()
        ..formulaExtraidaARetornar = const FormulaExtraida(
          fechaEmision: '2026-01-12',
          fechaVencimiento: '2026-02-12',
          farmaciaIpsOrigen: 'IPS Clínica Las Vegas',
          medicamentos: [Medicamento(nombre: 'Acetaminofen', concentracion: '500mg')],
        );
      final useCase = ExtraerDatosFormulaUseCase(repo);
      final bytes = [1, 2, 3];

      final resultado = await useCase.execute(
        bytes: bytes,
        nombreArchivo: 'formula.jpg',
        contentType: 'image/jpeg',
      );

      expect(repo.ultimaLlamada, {
        'metodo': 'extraerDatosFormula',
        'bytes': bytes,
        'nombreArchivo': 'formula.jpg',
        'contentType': 'image/jpeg',
      });
      expect(resultado.fechaEmision, '2026-01-12');
      expect(resultado.farmaciaIpsOrigen, 'IPS Clínica Las Vegas');
      expect(resultado.medicamentos.single.nombre, 'Acetaminofen');
    });

    test('propaga ApiException si el archivo es inválido o la imagen es ilegible', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(
          statusCode: 422,
          message: 'La imagen no es lo suficientemente clara.',
        );
      final useCase = ExtraerDatosFormulaUseCase(repo);

      expect(
        () => useCase.execute(bytes: [1], nombreArchivo: 'x.jpg', contentType: 'image/jpeg'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
