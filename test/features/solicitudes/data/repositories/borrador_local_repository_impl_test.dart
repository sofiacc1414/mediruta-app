import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/data/datasources/borrador_local_datasource.dart';
import 'package:mediruta_app/features/solicitudes/data/repositories/borrador_local_repository_impl.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/datos_solicitud.dart';
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

    test('guardar() persiste y leer() lo recupera igual', () async {
      const datos = DatosSolicitud(
        medicamentoNombre: 'Acetaminofén',
        direccionEntrega: 'Calle 1 #2-3',
      );

      await repository.guardar(datos);
      final leido = await repository.leer();

      expect(leido?.medicamentoNombre, 'Acetaminofén');
      expect(leido?.direccionEntrega, 'Calle 1 #2-3');
      expect(leido?.medicamentoConcentracion, isNull);
    });

    test('limpiar() borra el borrador guardado', () async {
      await repository.guardar(const DatosSolicitud(medicamentoNombre: 'Acetaminofén'));

      await repository.limpiar();

      expect(await repository.leer(), isNull);
    });

    test('guardar() sobrescribe el borrador anterior (una sola clave)', () async {
      await repository.guardar(const DatosSolicitud(medicamentoNombre: 'Primero'));
      await repository.guardar(const DatosSolicitud(medicamentoNombre: 'Segundo'));

      final leido = await repository.leer();

      expect(leido?.medicamentoNombre, 'Segundo');
    });
  });
}
