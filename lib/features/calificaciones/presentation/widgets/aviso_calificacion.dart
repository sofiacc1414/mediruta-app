import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_colors.dart';

class AvisoCalificacion extends StatelessWidget {
  const AvisoCalificacion({
    super.key,
    required this.icono,
    required this.titulo,
    required this.explicacion,
  });

  final IconData icono;
  final String titulo;
  final String explicacion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.beige,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: AppColors.navy, size: 32),
          ),
          const SizedBox(height: 18),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            explicacion,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.teal, height: 1.45, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class BotonCalificacion extends StatefulWidget {
  const BotonCalificacion({
    super.key,
    required this.etiqueta,
    required this.onPressed,
    this.relleno = true,
    this.cargando = false,
  });

  final String etiqueta;
  final VoidCallback? onPressed;
  final bool relleno;
  final bool cargando;

  @override
  State<BotonCalificacion> createState() => _BotonCalificacionState();
}

class _BotonCalificacionState extends State<BotonCalificacion> {
  double _escala = 1;

  @override
  Widget build(BuildContext context) {
    final child = widget.cargando
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.relleno ? AppColors.white : AppColors.navy,
            ),
          )
        : Text(
            widget.etiqueta,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontFamilyFallback: const ['Times New Roman', 'serif'],
              fontWeight: FontWeight.w500,
              fontSize: widget.relleno ? 17 : 15,
              letterSpacing: 0.2,
            ),
          );

    return GestureDetector(
      onTapDown: widget.onPressed == null || widget.cargando
          ? null
          : (_) => setState(() => _escala = 0.97),
      onTapCancel: () => setState(() => _escala = 1),
      onTapUp: (_) => setState(() => _escala = 1),
      child: AnimatedScale(
        scale: _escala,
        duration: const Duration(milliseconds: 120),
        child: widget.relleno
            ? DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.1),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: widget.cargando ? null : widget.onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.beige,
                    disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.45),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: child,
                ),
              )
            : TextButton(
                onPressed: widget.cargando ? null : widget.onPressed,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.teal,
                  minimumSize: const Size.fromHeight(40),
                ),
                child: child,
              ),
      ),
    );
  }
}

class ComparteTuExperiencia extends StatelessWidget {
  const ComparteTuExperiencia({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comparte tu momento favorito',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontFamilyFallback: ['Times New Roman', 'serif'],
            color: AppColors.navy,
            fontSize: 16,
            height: 1.15,
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            maxLength: 300,
            maxLines: 2,
            minLines: 1,
            onChanged: (_) => onChanged(),
            cursorColor: AppColors.teal,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontFamilyFallback: ['Times New Roman', 'serif'],
              color: AppColors.navy,
              height: 1.25,
              fontSize: 15,
            ),
            decoration: const InputDecoration(
              hintText: 'Si quieres, deja aquí una nota',
              hintStyle: TextStyle(
                fontFamily: 'Georgia',
                fontFamilyFallback: ['Times New Roman', 'serif'],
                fontStyle: FontStyle.italic,
                color: AppColors.teal,
                fontSize: 14,
                height: 1.25,
              ),
              filled: false,
              isCollapsed: true,
              contentPadding: EdgeInsets.only(top: 4),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}

class FondoExperiencia extends StatelessWidget {
  const FondoExperiencia({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.beige, AppColors.skyBlue],
        ),
      ),
      child: child,
    );
  }
}

class IlustracionExperiencia extends StatelessWidget {
  const IlustracionExperiencia({
    super.key,
    this.icono = Icons.medication_outlined,
    this.exito = false,
  });

  final IconData icono;
  final bool exito;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final alto = constraints.maxHeight.isFinite ? constraints.maxHeight : 280.0;
        return CustomPaint(
          painter: _EscenaCuidadoPainter(exito: exito),
          child: SizedBox(
            width: double.infinity,
            height: alto,
            child: Center(
          child: exito
              ? Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.teal, size: 48),
                )
              : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

class _EscenaCuidadoPainter extends CustomPainter {
  _EscenaCuidadoPainter({required this.exito});

  final bool exito;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2 + 8);
    final nube = Paint()..color = AppColors.skyBlue.withValues(alpha: 0.55);
    canvas.drawOval(
      Rect.fromCenter(center: centro.translate(-8, 18), width: 250, height: 150),
      nube,
    );
    canvas.drawCircle(centro.translate(108, -46), 28, Paint()..color = AppColors.white);
    canvas.drawCircle(
      centro.translate(-116, 36),
      16,
      Paint()..color = AppColors.beige,
    );

    final caja = RRect.fromRectAndRadius(
      Rect.fromCenter(center: centro.translate(0, 16), width: 118, height: 86),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      caja,
      Paint()
        ..color = AppColors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: centro.translate(0, -18), width: 128, height: 28),
        const Radius.circular(14),
      ),
      Paint()..color = AppColors.teal.withValues(alpha: 0.85),
    );

    _estrella(canvas, centro.translate(0, -62), 22, AppColors.navy);
    _corazon(canvas, centro.translate(78, -8), 8, AppColors.skyBlue);
    _corazon(canvas, centro.translate(-74, 8), 6, AppColors.teal.withValues(alpha: 0.7));

    if (!exito) {
      final cruz = Paint()
        ..color = AppColors.teal
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      final origen = centro.translate(0, 22);
      canvas.drawLine(origen.translate(0, -12), origen.translate(0, 12), cruz);
      canvas.drawLine(origen.translate(-12, 0), origen.translate(12, 0), cruz);
    }
  }

  void _estrella(Canvas canvas, Offset centro, double radio, Color color) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final angulo = -math.pi / 2 + i * 4 * math.pi / 5;
      final punto = centro + Offset(radio * math.cos(angulo), radio * math.sin(angulo));
      if (i == 0) {
        path.moveTo(punto.dx, punto.dy);
      } else {
        path.lineTo(punto.dx, punto.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _corazon(Canvas canvas, Offset centro, double radio, Color color) {
    final path = Path()
      ..addOval(Rect.fromCircle(center: centro.translate(-radio * 0.45, -radio * 0.2), radius: radio * 0.55))
      ..addOval(Rect.fromCircle(center: centro.translate(radio * 0.45, -radio * 0.2), radius: radio * 0.55));
    canvas.drawPath(path, Paint()..color = color);
    final punta = Path()
      ..moveTo(centro.dx - radio, centro.dy)
      ..lineTo(centro.dx + radio, centro.dy)
      ..lineTo(centro.dx, centro.dy + radio * 1.2)
      ..close();
    canvas.drawPath(punta, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _EscenaCuidadoPainter oldDelegate) => oldDelegate.exito != exito;
}
