import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/domain/usecases/subir_documento_domiciliario_usecase.dart';
import 'package:mediruta_app/features/usuarios/domain/value-objects/tipo_documento_domiciliario.dart';
import 'package:mediruta_app/shared/core/network/api_exception.dart';

import 'fake_perfil_repository.dart';

void main() {
  group('SubirDocumentoDomiciliarioUseCase', () {
    test('G01/G03 — delega tipo, bytes, nombre y content type', () async {
      final repo = FakePerfilRepository();
      final usecase = SubirDocumentoDomiciliarioUseCase(repo);
      final bytes = [1, 2, 3];

      await usecase.execute(
        tipo: TipoDocumentoDomiciliario.soat,
        bytes: bytes,
        nombreArchivo: 'soat.pdf',
        contentType: 'application/pdf',
      );

      expect(repo.ultimaLlamada, {
        'metodo': 'subirDocumentoDomiciliario',
        'tipo': TipoDocumentoDomiciliario.soat,
        'bytes': bytes,
        'nombreArchivo': 'soat.pdf',
        'contentType': 'application/pdf',
      });
    });

    test('propaga el error si la cuenta no tiene rol DOMICILIARIO', () async {
      final repo = FakePerfilRepository()
        ..errorALanzar = const ApiException(statusCode: 403, message: 'Rol no autorizado.');
      final usecase = SubirDocumentoDomiciliarioUseCase(repo);

      expect(
        () => usecase.execute(
          tipo: TipoDocumentoDomiciliario.licencia,
          bytes: [1],
          nombreArchivo: 'licencia.jpg',
          contentType: 'image/jpeg',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
