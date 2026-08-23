import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/subir_foto_perfil_usecase.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_perfil_repository.dart';

void main() {
  group('SubirFotoPerfilUseCase', () {
    test('delega bytes, nombre y content type — sin restricción de rol', () async {
      final repo = FakePerfilRepository();
      final usecase = SubirFotoPerfilUseCase(repo);
      final bytes = [1, 2, 3];

      await usecase.execute(
        bytes: bytes,
        nombreArchivo: 'foto.jpg',
        contentType: 'image/jpeg',
      );

      expect(repo.ultimaLlamada, {
        'metodo': 'subirFotoPerfil',
        'bytes': bytes,
        'nombreArchivo': 'foto.jpg',
        'contentType': 'image/jpeg',
      });
    });

    test('propaga el error si falla la subida', () async {
      final repo = FakePerfilRepository()
        ..errorALanzar = const ApiException(statusCode: 401, message: 'No autorizado.');
      final usecase = SubirFotoPerfilUseCase(repo);

      expect(
        () => usecase.execute(
          bytes: [1],
          nombreArchivo: 'foto.jpg',
          contentType: 'image/jpeg',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
