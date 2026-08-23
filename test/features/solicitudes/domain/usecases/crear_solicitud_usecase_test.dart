import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/datos_solicitud.dart';
import 'package:mediruta_app/features/solicitudes/domain/entities/medicamento.dart';
import 'package:mediruta_app/features/solicitudes/domain/usecases/crear_solicitud_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_solicitud_repository.dart';

void main() {
  group('CrearSolicitudUseCase', () {
    test('G01 — delega los datos en el repositorio y devuelve el id', () async {
      final repo = FakeSolicitudRepository()..idARetornar = 'nueva-uuid';
      final useCase = CrearSolicitudUseCase(repo);
      const datos = DatosSolicitud(
        medicamentos: [Medicamento(nombre: 'Acetaminofén')],
      );

      final resultado = await useCase.execute(datos);

      expect(resultado, 'nueva-uuid');
      expect(repo.ultimaLlamada, {'metodo': 'crear', 'datos': datos});
    });

    test('propaga el error si el perfil no tiene foto de cédula (HU-02)', () async {
      final repo = FakeSolicitudRepository()
        ..errorALanzar = const ApiException(
          statusCode: 403,
          message: 'Completa tu foto de cédula en tu perfil antes de crear una solicitud.',
        );
      final useCase = CrearSolicitudUseCase(repo);

      expect(
        () => useCase.execute(const DatosSolicitud()),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
