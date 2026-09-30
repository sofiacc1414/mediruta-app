import 'package:flutter_test/flutter_test.dart';

import 'package:mediruta_app/features/tracking/domain/posicion_en_vivo.dart';

void main() {
  test('PosicionEnVivo.fromJson parsea una posición completa', () {
    final posicion = PosicionEnVivo.fromJson({
      'estado': 'en_camino_entrega',
      'domiciliarioLat': 6.2449,
      'domiciliarioLng': -75.571,
      'ubicacionActualizadaEn': '2026-09-30T18:14:15.000Z',
      'farmaciaLat': 6.2442,
      'farmaciaLng': -75.5714,
      'entregaLat': 6.251,
      'entregaLng': -75.568,
    });

    expect(posicion.estado, 'en_camino_entrega');
    expect(posicion.domiciliarioLat, 6.2449);
    expect(posicion.ubicacionActualizadaEn, isNotNull);
    expect(posicion.farmaciaLat, 6.2442);
    expect(posicion.entregaLng, -75.568);
  });

  test('PosicionEnVivo.fromJson acepta ubicación del domiciliario null', () {
    final posicion = PosicionEnVivo.fromJson({
      'estado': 'en_camino_entrega',
      'domiciliarioLat': null,
      'domiciliarioLng': null,
      'ubicacionActualizadaEn': null,
      'farmaciaLat': 6.2442,
      'farmaciaLng': -75.5714,
      'entregaLat': 6.251,
      'entregaLng': -75.568,
    });

    expect(posicion.domiciliarioLat, isNull);
    expect(posicion.ubicacionActualizadaEn, isNull);
  });

  test('PosicionActualizada.fromJson parsea un ping en vivo', () {
    final posicion = PosicionActualizada.fromJson({
      'lat': 6.2449,
      'lng': -75.571,
      'actualizadoEn': '2026-09-30T18:14:15.000Z',
    });

    expect(posicion.lat, 6.2449);
    expect(posicion.lng, -75.571);
    expect(posicion.actualizadoEn, isNotNull);
  });
}
