import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/formula_extraida.dart';

void main() {
  group('FormulaExtraida.fromJson', () {
    test('mapea los campos y los medicamentos', () {
      final formula = FormulaExtraida.fromJson({
        'fechaEmision': '2026-01-12',
        'fechaVencimiento': '2026-02-12',
        'farmaciaIpsOrigen': 'IPS Clínica Las Vegas',
        'medicamentos': [
          {
            'nombre': 'Acetaminofen',
            'concentracion': '500mg',
            'formaFarmaceutica': null,
            'cantidad': null,
            'posologia': 'cada 8 horas · oral · por 5 dias',
          },
        ],
      });

      expect(formula.fechaEmision, '2026-01-12');
      expect(formula.fechaVencimiento, '2026-02-12');
      expect(formula.farmaciaIpsOrigen, 'IPS Clínica Las Vegas');
      expect(formula.medicamentos.single.nombre, 'Acetaminofen');
      expect(formula.medicamentos.single.concentracion, '500mg');
    });

    test('campos y lista de medicamentos faltantes no rompen', () {
      final formula = FormulaExtraida.fromJson({});

      expect(formula.fechaEmision, isNull);
      expect(formula.fechaVencimiento, isNull);
      expect(formula.farmaciaIpsOrigen, isNull);
      expect(formula.medicamentos, isEmpty);
    });
  });
}
