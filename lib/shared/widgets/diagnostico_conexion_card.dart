import 'package:flutter/material.dart';

import '../core/network/eventos_socket_service.dart';
import '../core/theme/app_colors.dart';

/// Widget TEMPORAL — muestra en vivo el estado de la conexión
/// WebSocket para diagnosticar por qué no conecta en ciertas redes
/// (ver `EventosSocketService.diagnostico`). Sacarla una vez
/// resuelto — no es una feature que deba quedar para usuarios finales.
class DiagnosticoConexionCard extends StatelessWidget {
  const DiagnosticoConexionCard({super.key, required this.servicio});

  final EventosSocketService servicio;

  Color _colorDe(FaseSocket fase) {
    switch (fase) {
      case FaseSocket.conectado:
        return Colors.green;
      case FaseSocket.conectando:
        return Colors.orange;
      case FaseSocket.error:
      case FaseSocket.desconectado:
        return Colors.red;
    }
  }

  String _etiquetaDe(FaseSocket fase) {
    switch (fase) {
      case FaseSocket.conectado:
        return 'Conectado';
      case FaseSocket.conectando:
        return 'Conectando...';
      case FaseSocket.error:
        return 'Error de conexión';
      case FaseSocket.desconectado:
        return 'Desconectado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DiagnosticoSocket>(
      valueListenable: servicio.diagnostico,
      builder: (context, estado, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: _colorDe(estado.fase),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WebSocket: ${_etiquetaDe(estado.fase)}'
                      '${estado.intentos > 0 ? ' (intento ${estado.intentos})' : ''}',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (estado.detalle != null) ...[
                      const SizedBox(height: 3),
                      SelectableText(
                        estado.detalle!,
                        style: TextStyle(
                          color: AppColors.navy.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
