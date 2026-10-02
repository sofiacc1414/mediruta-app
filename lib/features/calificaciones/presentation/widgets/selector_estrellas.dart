import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_colors.dart';

/// Frase emocional de la experiencia. Vive en la presentación para no
/// alterar las etiquetas de dominio que ya usa el resto de la HU.
String fraseExperiencia(int puntuacion) {
  return switch (puntuacion) {
    1 => 'Ojalá la próxima vez se sienta más cerca',
    2 => 'Gracias por abrirnos este momento',
    3 => 'Cuidarte es lo que nos mueve',
    4 => 'Qué bueno haber estado a tu lado',
    5 => 'Gracias por dejarnos acompañarte',
    _ => 'Un instante para agradecer',
  };
}

class SelectorEstrellas extends StatefulWidget {
  const SelectorEstrellas({
    super.key,
    required this.puntuacion,
    required this.onChanged,
    this.tamano = 64,
  });

  final int puntuacion;
  final ValueChanged<int> onChanged;
  final double tamano;

  @override
  State<SelectorEstrellas> createState() => _SelectorEstrellasState();
}

class _SelectorEstrellasState extends State<SelectorEstrellas> with SingleTickerProviderStateMixin {
  late final AnimationController _vuelo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _vuelo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const lugares = <(double, double, double)>[
      (0.02, 0.52, 0.72),
      (0.22, 0.12, 0.92),
      (0.42, 0.0, 1.18),
      (0.64, 0.16, 0.96),
      (0.82, 0.46, 0.74),
    ];
    return AnimatedBuilder(
      animation: _vuelo,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final ancho = constraints.maxWidth.isFinite ? constraints.maxWidth : 280.0;
            final alto = constraints.maxHeight.isFinite ? constraints.maxHeight : 110.0;
            final base = math.min(ancho * 0.2, alto * 0.62).clamp(22.0, widget.tamano);
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (var i = 0; i < lugares.length; i++)
                  _ubicar(
                    indice: i + 1,
                    lugar: lugares[i],
                    ancho: ancho,
                    alto: alto,
                    base: base,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _ubicar({
    required int indice,
    required (double, double, double) lugar,
    required double ancho,
    required double alto,
    required double base,
  }) {
    final lado = (base * lugar.$3).clamp(18.0, alto * 0.78).toDouble();
    final amplitud = math.min(6.0, alto * 0.06);
    final flotacion = math.sin((_vuelo.value * math.pi * 2) + indice) * amplitud;
    final izquierda = (ancho * lugar.$1).clamp(0.0, math.max(0.0, ancho - lado)).toDouble();
    final arriba = (alto * lugar.$2 + flotacion).clamp(0.0, math.max(0.0, alto - lado)).toDouble();
    return Positioned(
      left: izquierda,
      top: arriba,
      width: lado,
      height: lado,
      child: _Estrella(
        key: Key('estrella-$indice'),
        activa: indice <= widget.puntuacion,
        destacada: indice == widget.puntuacion,
        onTap: () => widget.onChanged(indice),
      ),
    );
  }
}

class _Estrella extends StatelessWidget {
  const _Estrella({
    super.key,
    required this.activa,
    required this.destacada,
    required this.onTap,
  });

  final bool activa;
  final bool destacada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('$activa-$destacada'),
      tween: Tween(begin: destacada ? 0.7 : 0.92, end: destacada ? 1.08 : 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutBack,
      builder: (context, escala, child) => Transform.scale(scale: escala, child: child),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: CustomPaint(
          painter: _EstrellaPainter(activa: activa, destacada: destacada),
        ),
      ),
    );
  }
}

class _EstrellaPainter extends CustomPainter {
  const _EstrellaPainter({required this.activa, required this.destacada});

  final bool activa;
  final bool destacada;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.shortestSide * 0.42;
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
    if (destacada) {
      canvas.drawCircle(
        centro,
        radio * 1.15,
        Paint()..color = AppColors.skyBlue.withValues(alpha: 0.9),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = activa ? AppColors.navy : AppColors.teal.withValues(alpha: 0.55)
        ..style = activa ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _EstrellaPainter oldDelegate) {
    return oldDelegate.activa != activa || oldDelegate.destacada != destacada;
  }
}

class FilaEstrellas extends StatelessWidget {
  const FilaEstrellas({super.key, required this.puntuacion, this.tamano = 28});

  final int puntuacion;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth.isFinite ? constraints.maxWidth : tamano * 5;
        final lado = (ancho / 5 * 0.8).clamp(18.0, tamano);
        return Row(
          children: [
            for (var i = 1; i <= 5; i++)
              Expanded(
                child: Icon(
                  i <= puntuacion ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i <= puntuacion ? AppColors.navy : AppColors.teal.withValues(alpha: 0.45),
                  size: lado,
                ),
              ),
          ],
        );
      },
    );
  }
}
