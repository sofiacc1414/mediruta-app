package com.mediruta.mediruta_app

import io.flutter.embedding.android.FlutterFragmentActivity

// `local_auth` requiere `FlutterFragmentActivity` (no `FlutterActivity`)
// para poder mostrar el diálogo nativo de huella/clave del teléfono.
class MainActivity : FlutterFragmentActivity()
