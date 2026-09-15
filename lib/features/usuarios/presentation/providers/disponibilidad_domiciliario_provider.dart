import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../shared/core/network/api_exception.dart';
import 'perfil_providers.dart';

/// Estado de "Disponible para recibir pedidos" del Domiciliario —
/// vivía como estado local de `HomeScreen`, pero la barra de
/// navegación ahora es persistente en toda la app y necesita saber si
/// está en línea (para mostrar o no "Pedidos disponibles") sin
/// importar en qué pantalla esté parado.
class DisponibilidadDomiciliarioState {
  const DisponibilidadDomiciliarioState({
    this.disponible = false,
    this.actualizando = false,
    this.error,
  });

  // "Disponible" arranca apagado en cada apertura de la app (mismo
  // criterio que la mayoría de apps de repartidores: no asumir
  // disponibilidad de una sesión anterior) — la API no expone todavía
  // el valor guardado en un GET de perfil, así que no hay de dónde
  // leer el estado real al abrir.
  final bool disponible;
  final bool actualizando;
  final String? error;

  DisponibilidadDomiciliarioState copyWith({
    bool? disponible,
    bool? actualizando,
    String? error,
    bool limpiarError = false,
  }) {
    return DisponibilidadDomiciliarioState(
      disponible: disponible ?? this.disponible,
      actualizando: actualizando ?? this.actualizando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

class DisponibilidadDomiciliarioNotifier extends StateNotifier<DisponibilidadDomiciliarioState> {
  DisponibilidadDomiciliarioNotifier(this._ref) : super(const DisponibilidadDomiciliarioState());

  final Ref _ref;

  /// Al activar, pide permiso de ubicación y lee la posición actual —
  /// obligatoria para entrar al pool (`app.listar_pedidos_disponibles`
  /// filtra por `ubicacion`). Al desactivar no hace falta ubicación.
  Future<void> cambiar(bool valor) async {
    state = state.copyWith(actualizando: true, limpiarError: true);
    try {
      double? lat;
      double? lng;
      if (valor) {
        final posicion = await _obtenerUbicacionActual();
        if (posicion == null) {
          state = state.copyWith(
            actualizando: false,
            error: 'Necesitamos permiso de ubicación para activar "Disponible".',
          );
          return;
        }
        lat = posicion.latitude;
        lng = posicion.longitude;
      }
      await _ref
          .read(actualizarDisponibilidadDomiciliarioUseCaseProvider)
          .execute(disponible: valor, lat: lat, lng: lng);
      state = state.copyWith(disponible: valor, actualizando: false, limpiarError: true);
    } on ApiException catch (error) {
      state = state.copyWith(actualizando: false, error: error.message);
    } on ApiSinConexionException catch (error) {
      state = state.copyWith(actualizando: false, error: error.toString());
    }
  }

  Future<Position?> _obtenerUbicacionActual() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition();
  }

  /// Refresca la "foto instantánea" de ubicación sin pasar por el flujo
  /// de `cambiar()` (que es para el toggle manual y expone error en la
  /// UI). Se usa justo después de entregar un pedido: hasta ahora la
  /// única vez que `perfil_domiciliario.ubicacion` se actualizaba era
  /// al prender "Disponible" — si el domiciliario nunca lo apaga entre
  /// un pedido y el siguiente (lo normal), esa posición quedaba
  /// congelada en donde estaba al prenderlo la primera vez, aunque ya
  /// haya recorrido kilómetros entregando. Eso hacía que el pool del
  /// siguiente pedido (`ST_DWithin`, ver `listar_pedidos_disponibles`)
  /// lo siguiera viendo "cerca" de una farmacia de la que en realidad
  /// ya se alejó. Silencioso a propósito (sin tocar `error`/
  /// `actualizando`): si falla (sin señal GPS justo en ese momento,
  /// permiso revocado, etc.) el domiciliario simplemente sigue con la
  /// ubicación anterior — no es peor que el comportamiento actual, y no
  /// tiene sentido interrumpirlo con un error por algo que no disparó
  /// a propósito.
  Future<void> refrescarUbicacionTrasEntrega() async {
    if (!state.disponible) return;
    try {
      final posicion = await _obtenerUbicacionActual();
      if (posicion == null) return;
      await _ref
          .read(actualizarDisponibilidadDomiciliarioUseCaseProvider)
          .execute(
            disponible: true,
            lat: posicion.latitude,
            lng: posicion.longitude,
          );
    } catch (_) {
      // Best-effort: ver doc del método.
    }
  }
}

final disponibilidadDomiciliarioProvider =
    StateNotifierProvider<DisponibilidadDomiciliarioNotifier, DisponibilidadDomiciliarioState>(
      (ref) => DisponibilidadDomiciliarioNotifier(ref),
    );
