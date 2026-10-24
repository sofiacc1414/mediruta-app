import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/shared_preferences_provider.dart';

const _clave = 'modo_oscuro';

/// "Modo oscuro" (Perfil → Apariencia) — persistido, mismo patrón que
/// `modoAdultoMayorProvider`. `AppColors.configurar()` lo aplica en la
/// raíz de la app (`main.dart`).
class ModoOscuroNotifier extends StateNotifier<bool> {
  ModoOscuroNotifier(this._prefs) : super(_prefs.getBool(_clave) ?? false);

  final SharedPreferences _prefs;

  Future<void> cambiar(bool valor) async {
    state = valor;
    await _prefs.setBool(_clave, valor);
  }
}

final modoOscuroProvider = StateNotifierProvider<ModoOscuroNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ModoOscuroNotifier(prefs);
});
