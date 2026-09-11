import 'package:flutter/material.dart';

import '../core/network/eventos_socket_service.dart';

/// Punto de estado del WebSocket — versión mínima de
/// `DiagnosticoConexionCard` (la tarjeta completa con el detalle
/// técnico ya cumplió su propósito de diagnóstico y se retiró). Solo
/// un círculo de color: verde conectado, gris desconectado/conectando
/// — no hace falta más que eso para el uso normal, el poll de 15s
/// sigue siendo la garantía real de que todo se actualice igual.
class IndicadorConexion extends StatelessWidget {
  const IndicadorConexion({super.key, required this.servicio});

  final EventosSocketService servicio;

  Color _colorDe(FaseSocket fase) {
    switch (fase) {
      case FaseSocket.conectado:
        return Colors.green;
      case FaseSocket.conectando:
      case FaseSocket.desconectado:
      case FaseSocket.error:
        return Colors.grey;
    }
  }

  String _etiquetaDe(FaseSocket fase) {
    switch (fase) {
      case FaseSocket.conectado:
        return 'Conectado en tiempo real';
      case FaseSocket.conectando:
        return 'Conectando...';
      case FaseSocket.desconectado:
      case FaseSocket.error:
        return 'Sin conexión en tiempo real — se sigue actualizando cada 15s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DiagnosticoSocket>(
      valueListenable: servicio.diagnostico,
      builder: (context, estado, _) {
        return Tooltip(
          message: _etiquetaDe(estado.fase),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _colorDe(estado.fase),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
