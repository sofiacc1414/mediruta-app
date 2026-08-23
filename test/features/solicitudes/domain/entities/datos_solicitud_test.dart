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

// Fecha bien futura a propósito — una fecha de vencimiento válida no
// puede quedar vieja con el paso del tiempo como pasaría con una fecha
// fija cercana (ya nos pasó con '2026-08-01' al reemplazar expedición
// por vencimiento: dejó de estar "vacío").
const _vencimientoVigente = '2099-08-01';

void main() {
  group('DatosSolicitud.calcularFaltantes', () {
    test('G05 — lista los 4 requisitos si todo está vacío', () {
      const datos = DatosSolicitud();

      expect(datos.calcularFaltantes(tieneRecetaSubida: false), [
        'Al menos un medicamento',
        'Foto de la receta',
        'Fecha de vencimiento de la receta',
        'Dirección de entrega',
      ]);
    });

    test('vacío si hay al menos un medicamento completo, receta, fecha vigente y dirección', () {
      const datos = DatosSolicitud(
        medicamentos: [_medicamentoCompleto],
        recetaFechaVencimiento: _vencimientoVigente,
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
        recetaFechaVencimiento: _vencimientoVigente,
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
        recetaFechaVencimiento: _vencimientoVigente,
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
        recetaFechaVencimiento: _vencimientoVigente,
        direccionEntrega: 'Calle 1 #2-3',
      );

      expect(
        datos.calcularFaltantes(tieneRecetaSubida: false),
        contains('Foto de la receta'),
      );
    });

    test('receta con fecha de vencimiento ya pasada avisa que está vencida', () {
      const datos = DatosSolicitud(
        medicamentos: [_medicamentoCompleto],
        recetaFechaVencimiento: '2020-01-01',
        direccionEntrega: 'Calle 1 #2-3',
      );

      expect(
        datos.calcularFaltantes(tieneRecetaSubida: true),
        contains('La receta está vencida — sube una foto de una receta vigente'),
      );
    });

    test('receta que vence justo hoy no cuenta como vencida', () {
      final hoy = DateTime.now();
      final hoyIso =
          '${hoy.year.toString().padLeft(4, '0')}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
      final datos = DatosSolicitud(
        medicamentos: const [_medicamentoCompleto],
        recetaFechaVencimiento: hoyIso,
        direccionEntrega: 'Calle 1 #2-3',
      );

      expect(datos.calcularFaltantes(tieneRecetaSubida: true), isEmpty);
    });
  });
}
