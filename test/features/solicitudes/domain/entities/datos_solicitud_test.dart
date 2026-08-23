import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/datos_solicitud.dart';

void main() {
  group('DatosSolicitud.calcularFaltantes', () {
    test('G05 — lista los 10 requisitos si todo está vacío', () {
      const datos = DatosSolicitud();

      expect(datos.calcularFaltantes(), [
        'Nombre del medicamento',
        'Concentración/dosis',
        'Forma farmacéutica',
        'Cantidad solicitada',
        'Posología',
        'Nombre del médico',
        'Registro médico',
        'IPS',
        'Fecha de expedición de la receta',
        'Dirección de entrega',
      ]);
    });

    test('vacío si todos los campos están completos', () {
      const datos = DatosSolicitud(
        medicamentoNombre: 'Acetaminofén',
        medicamentoConcentracion: '500mg',
        medicamentoFormaFarmaceutica: 'Tableta',
        medicamentoCantidad: '30 tabletas',
        medicamentoPosologia: 'Cada 8 horas por 7 días',
        recetaMedicoNombre: 'Dra. Ana Pérez',
        recetaMedicoRegistro: 'RM12345',
        recetaIps: 'IPS Central',
        recetaFechaExpedicion: '2026-08-01',
        direccionEntrega: 'Calle 1 #2-3',
      );

      expect(datos.calcularFaltantes(), isEmpty);
    });

    test('un campo con solo espacios cuenta como vacío', () {
      const datos = DatosSolicitud(medicamentoNombre: '   ');

      expect(datos.calcularFaltantes(), contains('Nombre del medicamento'));
    });
  });
}
