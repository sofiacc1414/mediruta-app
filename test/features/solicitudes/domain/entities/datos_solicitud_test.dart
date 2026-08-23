import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/datos_solicitud.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/medicamento.dart';

const _medicamentoCompleto = Medicamento(
  nombre: 'Acetaminofén',
  concentracion: '500mg',
  formaFarmaceutica: 'Tableta',
  cantidad: '30 tabletas',
  posologia: 'Cada 8 horas por 7 días',
);

void main() {
  group('DatosSolicitud.calcularFaltantes', () {
    test('G05 — lista los 4 requisitos si todo está vacío', () {
      const datos = DatosSolicitud();

      expect(datos.calcularFaltantes(tieneRecetaSubida: false), [
        'Al menos un medicamento',
        'Foto de la receta',
        'Fecha de expedición de la receta',
        'Dirección de entrega',
      ]);
    });

    test('vacío si hay al menos un medicamento completo, receta, fecha y dirección', () {
      const datos = DatosSolicitud(
        medicamentos: [_medicamentoCompleto],
        recetaFechaExpedicion: '2026-08-01',
        direccionEntrega: 'Calle 1 #2-3',
      );

      expect(datos.calcularFaltantes(tieneRecetaSubida: true), isEmpty);
    });

    test('un medicamento incompleto entre varios completos avisa que falta completar', () {
      const datos = DatosSolicitud(
        medicamentos: [
          _medicamentoCompleto,
          Medicamento(nombre: 'Ibuprofeno'),
        ],
        recetaFechaExpedicion: '2026-08-01',
        direccionEntrega: 'Calle 1 #2-3',
      );

      expect(
        datos.calcularFaltantes(tieneRecetaSubida: true),
        contains('Completar todos los campos de cada medicamento'),
      );
    });

    test('líneas de medicamento totalmente vacías no cuentan como "al menos uno"', () {
      const datos = DatosSolicitud(
        medicamentos: [Medicamento()],
        recetaFechaExpedicion: '2026-08-01',
        direccionEntrega: 'Calle 1 #2-3',
      );

      expect(
        datos.calcularFaltantes(tieneRecetaSubida: true),
        contains('Al menos un medicamento'),
      );
    });

    test('sin receta subida avisa "Foto de la receta"', () {
      const datos = DatosSolicitud(
        medicamentos: [_medicamentoCompleto],
        recetaFechaExpedicion: '2026-08-01',
        direccionEntrega: 'Calle 1 #2-3',
      );

      expect(
        datos.calcularFaltantes(tieneRecetaSubida: false),
        contains('Foto de la receta'),
      );
    });
  });
}
