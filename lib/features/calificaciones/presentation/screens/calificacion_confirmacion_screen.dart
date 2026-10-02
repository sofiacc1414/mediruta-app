import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_colors.dart';
import '../widgets/aviso_calificacion.dart';
import 'pedidos_calificacion_screen.dart';

class CalificacionConfirmacionScreen extends StatefulWidget {
  const CalificacionConfirmacionScreen({super.key, required this.pedidoId});

  static const routeName = '/pedidos-calificacion/gracias';

  final String pedidoId;

  @override
  State<CalificacionConfirmacionScreen> createState() =>
      _CalificacionConfirmacionScreenState();
}

class _CalificacionConfirmacionScreenState extends State<CalificacionConfirmacionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final escala = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return Scaffold(
      key: ValueKey(widget.pedidoId),
      backgroundColor: AppColors.beige,
      body: FondoExperiencia(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final imagen = (constraints.maxHeight * 0.42).clamp(160.0, constraints.maxHeight * 0.48);
                return Column(
                  children: [
                    const Spacer(),
                    ScaleTransition(
                      scale: escala,
                      child: SizedBox(
                        height: imagen,
                        width: double.infinity,
                        child: Image.asset(
                          'assets/images/GraciasCalificacion.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: fade,
                      child: const Column(
                        children: [
                          Text(
                            '¡Gracias por compartir!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontFamilyFallback: ['Times New Roman', 'serif'],
                              color: AppColors.navy,
                              fontSize: 32,
                              height: 1.12,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Tu opinión nos ayuda a mejorar cada entrega.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.teal, height: 1.4, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    BotonCalificacion(
                      etiqueta: 'Volver a mis pedidos',
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          PedidosCalificacionScreen.routeName,
                          (route) => route.isFirst,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
