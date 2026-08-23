import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/data/datasources/borrador_local_datasource.dart';
import 'package:mediruta_app/features/solicitudes/data/repositories/borrador_local_repository_impl.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/datos_solicitud.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/medicamento.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('BorradorLocalRepositoryImpl', () {
    late BorradorLocalRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repository = BorradorLocalRepositoryImpl(BorradorLocalDatasource(prefs));
    });

    test('leer() devuelve null si no hay borrador guardado', () async {
      expect(await repository.leer(), isNull);
    });

    test('guardar() persiste y leer() lo recupera igual, incluidos los medicamentos', () async {
      const datos = DatosSolicitud(
        medicamentos: [Medicamento(nombre: 'Acetaminofén', concentracion: '500mg')],
        direccionEntrega: 'Calle 1 #2-3',
      );

      await repository.guardar(datos);
      final leido = await repository.leer();

      expect(leido?.medicamentos, hasLength(1));
      expect(leido?.medicamentos.first.nombre, 'Acetaminofén');
      expect(leido?.medicamentos.first.concentracion, '500mg');
      expect(leido?.direccionEntrega, 'Calle 1 #2-3');
    });

    test('limpiar() borra el borrador guardado', () async {
      await repository.guardar(
        const DatosSolicitud(medicamentos: [Medicamento(nombre: 'Acetaminofén')]),
      );

      await repository.limpiar();

      expect(await repository.leer(), isNull);
    });

    test('guardar() sobrescribe el borrador anterior (una sola clave)', () async {
      await repository.guardar(
        const DatosSolicitud(medicamentos: [Medicamento(nombre: 'Primero')]),
      );
      await repository.guardar(
        const DatosSolicitud(medicamentos: [Medicamento(nombre: 'Segundo')]),
      );

      final leido = await repository.leer();

      expect(leido?.medicamentos.first.nombre, 'Segundo');
    });
  });
}
