import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Abre la imagen (bytes locales todavía no subidos, o ya subida vía
/// `url` firmada) en pantalla completa, con zoom/pan (`InteractiveViewer`
/// nativo — sin agregar un paquete nuevo solo para esto). Pensado para
/// documentos/recetas: una miniatura de 44px sirve para confirmar "hay
/// algo cargado", pero no alcanza para poder leerlo.
///
/// Pasá exactamente uno de `bytes`/`url` — si vinieran los dos, gana
/// `bytes` (la versión más reciente, todavía no reflejada en el server).
Future<void> mostrarImagenCompleta(
  BuildContext context, {
  Uint8List? bytes,
  String? url,
}) {
  assert(bytes != null || url != null, 'Se necesita bytes o url.');
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (context, animacion, animacionSecundaria) =>
          _VisorImagenPantallaCompleta(bytes: bytes, url: url),
    ),
  );
}

class _VisorImagenPantallaCompleta extends StatelessWidget {
  const _VisorImagenPantallaCompleta({this.bytes, this.url});

  final Uint8List? bytes;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: bytes != null
                ? Image.memory(bytes!, fit: BoxFit.contain)
                : Image.network(
                    url!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const CircularProgressIndicator(color: AppColors.white);
                    },
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.white,
                      size: 48,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
