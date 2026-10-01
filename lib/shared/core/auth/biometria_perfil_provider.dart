import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/shared_preferences_provider.dart';

const _clave = 'biometria_perfil_activa';

/// Preferencia local (por dispositivo, no sincroniza con el backend)
/// de si hay que pedir huella/clave del teléfono para entrar a
/// `PerfilScreen` — mismo molde que `ModoAdultoMayorNotifier`.
class BiometriaPerfilNotifier extends StateNotifier<bool> {
  BiometriaPerfilNotifier(this._prefs) : super(_prefs.getBool(_clave) ?? false);

  final SharedPreferences _prefs;

  Future<void> cambiar(bool valor) async {
    state = valor;
    await _prefs.setBool(_clave, valor);
  }
}

final biometriaPerfilProvider = StateNotifierProvider<BiometriaPerfilNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BiometriaPerfilNotifier(prefs);
});
