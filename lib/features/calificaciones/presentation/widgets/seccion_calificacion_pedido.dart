import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../domain/entities/calificacion.dart';
import '../providers/calificacion_providers.dart';
import '../screens/calificacion_form_screen.dart';
import 'selector_estrellas.dart';

/// Sección "Tu calificación" en el detalle del pedido (pantalla 4).
class SeccionCalificacionPedido extends ConsumerStatefulWidget {
  const SeccionCalificacionPedido({
    super.key,
    required this.pedidoId,
    required this.codigoPedido,
    required this.estadoPedido,
  });

  final String pedidoId;
  final String? codigoPedido;
  final String estadoPedido;

  @override
  ConsumerState<SeccionCalificacionPedido> createState() =>
      _SeccionCalificacionPedidoState();
}

class _SeccionCalificacionPedidoState extends ConsumerState<SeccionCalificacionPedido> {
  Calificacion? _calificacion;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (widget.estadoPedido != 'entregado') {
      setState(() => _cargando = false);
      return;
    }
    try {
      final calificacion =
          await ref.read(consultarCalificacionUseCaseProvider).execute(widget.pedidoId);
      if (!mounted) return;
      setState(() => _calificacion = calificacion);
    } on ApiException {
      if (mounted) setState(() => _calificacion = null);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.estadoPedido != 'entregado' || _cargando) {
      return const SizedBox.shrink();
    }
    if (_calificacion == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Material(
          color: AppColors.white,
          elevation: 0,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () async {
              await Navigator.of(context).pushNamed(
                CalificacionFormScreen.routeName,
                arguments: CalificacionFormArgs(
                  pedidoId: widget.pedidoId,
                  codigoPedido: widget.codigoPedido,
                  estadoPedido: widget.estadoPedido,
                  editar: false,
                ),
              );
              _cargar();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Text(
                    'Tu experiencia',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontFamilyFallback: ['Times New Roman', 'serif'],
                      color: AppColors.navy,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Cuéntanos cómo fue tu entrega',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.teal, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final calificacion = _calificacion!;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tu experiencia',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontFamilyFallback: ['Times New Roman', 'serif'],
                      color: AppColors.navy,
                      fontSize: 22,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.of(context).pushNamed(
                      CalificacionFormScreen.routeName,
                      arguments: CalificacionFormArgs(
                        pedidoId: widget.pedidoId,
                        codigoPedido: widget.codigoPedido,
                        estadoPedido: widget.estadoPedido,
                        editar: true,
                      ),
                    );
                    _cargar();
                  },
                  child: const Text('Editar', style: TextStyle(color: AppColors.teal)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FilaEstrellas(puntuacion: calificacion.puntuacion, tamano: 46),
            const SizedBox(height: 8),
            Text(
              fraseExperiencia(calificacion.puntuacion),
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _fecha(calificacion.creadoEn),
              style: const TextStyle(color: AppColors.teal, fontSize: 12),
            ),
            if (calificacion.comentario != null && calificacion.comentario!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.beige,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  calificacion.comentario!,
                  style: const TextStyle(color: AppColors.navy, height: 1.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _fecha(String iso) {
  final fecha = DateTime.tryParse(iso)?.toLocal();
  if (fecha == null) return iso;
  const meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
}
