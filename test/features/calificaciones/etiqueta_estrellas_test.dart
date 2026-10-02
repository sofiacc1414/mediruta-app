import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/calificaciones/domain/etiqueta_estrellas.dart';

void main() {
  test('cada puntuación tiene su etiqueta', () {
    expect(etiquetaEstrellas(1), 'Muy mala');
    expect(etiquetaEstrellas(2), 'Mala');
    expect(etiquetaEstrellas(3), 'Regular');
    expect(etiquetaEstrellas(4), 'Muy buena');
    expect(etiquetaEstrellas(5), 'Excelente');
    expect(etiquetaEstrellas(0), '');
  });
}
