import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Wrapper fino sobre `local_auth` — segundo factor LOCAL del
/// dispositivo (huella/Face ID/clave del teléfono), no un 2FA remoto
/// con OTP contra la API. `local_auth` no soporta Web — en esa
/// plataforma [disponibleEnEsteDispositivo] siempre da `false` y el
/// gate de `PerfilScreen` se salta solo.
class BiometriaService {
  final _auth = LocalAuthentication();

  Future<bool> disponibleEnEsteDispositivo() async {
    if (kIsWeb) return false;
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// `biometricOnly: false` es lo que pide el usuario: si el
  /// dispositivo no tiene huella/Face ID enrolada, el propio sistema
  /// operativo ofrece la clave/PIN/patrón como alternativa — no hace
  /// falta programar ese fallback a mano.
  Future<bool> autenticar({required String motivo}) async {
    try {
      return await _auth.authenticate(
        localizedReason: motivo,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
