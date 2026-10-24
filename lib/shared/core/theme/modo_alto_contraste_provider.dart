import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/shared_preferences_provider.dart';

const _clave = 'modo_alto_contraste';

/// "Alto contraste" (Perfil → Accesibilidad) — independiente de modo
/// oscuro: se puede combinar con claro u oscuro. Mismo patrón que
/// `modoAdultoMayorProvider`.
class ModoAltoContrasteNotifier extends StateNotifier<bool> {
  ModoAltoContrasteNotifier(this._prefs) : super(_prefs.getBool(_clave) ?? false);

  final SharedPreferences _prefs;

  Future<void> cambiar(bool valor) async {
    state = valor;
    await _prefs.setBool(_clave, valor);
  }
}

final modoAltoContrasteProvider = StateNotifierProvider<ModoAltoContrasteNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ModoAltoContrasteNotifier(prefs);
});
