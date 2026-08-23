import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `SharedPreferences.getInstance()` es async, así que la instancia se
/// resuelve una sola vez en `main()` (antes de `runApp`) y se inyecta acá
/// vía `overrideWithValue` — patrón estándar de Riverpod para
/// dependencias de inicialización async. Ningún provider debería llamar
/// a esto sin que `main()` ya haya hecho el override.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider debe overridearse en main() con la instancia ya resuelta.',
  );
});
