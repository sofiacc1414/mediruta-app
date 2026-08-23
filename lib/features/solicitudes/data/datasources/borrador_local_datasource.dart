import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Único borrador de "Nueva solicitud" en progreso — vive en el
/// dispositivo (nunca en la API/BD) mientras el paciente todavía no
/// confirmó crearlo. Una sola clave: solo se soporta un borrador nuevo
/// sin confirmar a la vez, que es el flujo real (context.md no exige
/// borradores concurrentes).
class BorradorLocalDatasource {
  const BorradorLocalDatasource(this._prefs);

  final SharedPreferences _prefs;

  static const _clave = 'solicitud_borrador_local';

  Future<void> guardar(Map<String, dynamic> datos) async {
    await _prefs.setString(_clave, jsonEncode(datos));
  }

  Map<String, dynamic>? leer() {
    final crudo = _prefs.getString(_clave);
    if (crudo == null) return null;
    return jsonDecode(crudo) as Map<String, dynamic>;
  }

  Future<void> limpiar() async {
    await _prefs.remove(_clave);
  }
}
