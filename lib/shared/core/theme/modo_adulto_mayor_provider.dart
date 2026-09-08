import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/shared_preferences_provider.dart';

const _clave = 'modo_adulto_mayor';

/// Escala de texto que aplica `MediaQuery` en toda la app cuando el
/// modo está activo — 1.3x el tamaño normal. Se define acá (no en el
/// widget del switch) porque `main.dart` también lo necesita, para
/// envolver el `MaterialApp` entero.
const escalaTextoAdultoMayor = 1.3;

/// "Modo adulto mayor" (Perfil) — antes era un `bool` local de
/// `PerfilScreen` que no hacía nada más que prenderse/apagarse: no
/// afectaba ninguna pantalla. Ahora vive acá, persistido (sobrevive a
/// cerrar la app) y aplicado globalmente vía `MediaQuery.textScaler`
/// en `main.dart`.
class ModoAdultoMayorNotifier extends StateNotifier<bool> {
  ModoAdultoMayorNotifier(this._prefs) : super(_prefs.getBool(_clave) ?? false);

  final SharedPreferences _prefs;

  Future<void> cambiar(bool valor) async {
    state = valor;
    await _prefs.setBool(_clave, valor);
  }
}

final modoAdultoMayorProvider = StateNotifierProvider<ModoAdultoMayorNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ModoAdultoMayorNotifier(prefs);
});
