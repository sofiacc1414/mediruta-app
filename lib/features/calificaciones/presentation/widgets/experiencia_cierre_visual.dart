import 'dart:math' as math;

import 'package:flutter/material.dart';

const _beige = Color(0xFFF5EFEB);
const _cielo = Color(0xFFC8D9E6);
const _navy = Color(0xFF2F4156);
const _teal = Color(0xFF567C8D);
const _oroClaro = Color(0xFFFFF3CC);
const _oro = Color(0xFFE4B15A);
const _oroProfundo = Color(0xFFB8862F);

String fraseCierre(int puntuacion) {
  return switch (puntuacion) {
    1 => 'Queremos seguir mejorando contigo',
    2 => 'Gracias por ayudarnos a crecer',
    3 => 'Gracias por compartir tu experiencia',
    4 => 'Nos alegra acompañarte',
    5 => 'Gracias por confiar en MediRuta',
    _ => 'Este momento es tuyo',
  };
}

class ExperienciaFondo extends StatelessWidget {
  const ExperienciaFondo({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_beige, _cielo],
        ),
      ),
      child: child,
    );
  }
}

class EscenaExperiencia extends StatelessWidget {
  const EscenaExperiencia({
    super.key,
    required this.editar,
    required this.puntuacion,
    required this.onPuntuacion,
    required this.comentario,
    required this.onComentario,
    required this.onEnviar,
    required this.enviando,
    this.onRetirar,
    this.error,
  });

  final bool editar;
  final int puntuacion;
  final ValueChanged<int> onPuntuacion;
  final TextEditingController comentario;
  final VoidCallback onComentario;
  final VoidCallback onEnviar;
  final VoidCallback? onRetirar;
  final bool enviando;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final teclado = MediaQuery.viewInsetsOf(context).bottom > 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final escena = _ColumnaCierre(
          editar: editar,
          alto: constraints.maxHeight,
          teclado: teclado,
          puntuacion: puntuacion,
          onPuntuacion: onPuntuacion,
          comentario: comentario,
          onComentario: onComentario,
          onEnviar: onEnviar,
          onRetirar: onRetirar,
          enviando: enviando,
          error: error,
        );
        if (!teclado) return escena;
        return SingleChildScrollView(child: escena);
      },
    );
  }
}

class _ColumnaCierre extends StatelessWidget {
  const _ColumnaCierre({
    required this.editar,
    required this.alto,
    required this.teclado,
    required this.puntuacion,
    required this.onPuntuacion,
    required this.comentario,
    required this.onComentario,
    required this.onEnviar,
    required this.onRetirar,
    required this.enviando,
    required this.error,
  });

  final bool editar;
  final double alto;
  final bool teclado;
  final int puntuacion;
  final ValueChanged<int> onPuntuacion;
  final TextEditingController comentario;
  final VoidCallback onComentario;
  final VoidCallback onEnviar;
  final VoidCallback? onRetirar;
  final bool enviando;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final compacto = alto < 700 || teclado;
    final portada = Image.asset(
      editar ? 'assets/images/editarcalificacion.png' : 'assets/images/Calificacion.png',
      fit: BoxFit.contain,
    );
    final titulo = Text(
      editar ? 'Edita tu experiencia' : 'Tu experiencia con MediRuta',
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Georgia',
        fontFamilyFallback: const ['Times New Roman', 'serif'],
        color: _navy,
        fontSize: compacto ? 22 : 30,
        height: 1.05,
        fontWeight: FontWeight.w400,
      ),
    );
    final estrellas = EstrellasVolumen(
      puntuacion: puntuacion,
      onChanged: onPuntuacion,
    );
    final frase = _FraseCierre(puntuacion: puntuacion, compacto: compacto);
    final carta = CartaMomento(controller: comentario, onChanged: onComentario);
    final cierre = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              error!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _navy, fontSize: 13),
            ),
          ),
        CierreExperiencia(
          etiqueta: editar ? 'Guardar cambios' : 'Compartir mi experiencia',
          onPressed: onEnviar,
          cargando: enviando,
        ),
        if (editar && onRetirar != null)
          TextButton(
            onPressed: enviando ? null : onRetirar,
            style: TextButton.styleFrom(
              foregroundColor: _teal,
              minimumSize: const Size.fromHeight(34),
            ),
            child: const Text(
              'Retirar experiencia',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontFamilyFallback: ['Times New Roman', 'serif'],
                fontSize: 15,
              ),
            ),
          ),
      ],
    );

    if (teclado) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 128, width: double.infinity, child: portada),
          titulo,
          const SizedBox(height: 2),
          estrellas,
          frase,
          SizedBox(height: 92, child: carta),
          const SizedBox(height: 8),
          cierre,
        ],
      );
    }

    return SizedBox(
      height: alto,
      child: Column(
        children: [
          Expanded(child: portada),
          titulo,
          const SizedBox(height: 2),
          estrellas,
          frase,
          SizedBox(height: compacto ? 92 : 108, child: carta),
          const SizedBox(height: 8),
          cierre,
        ],
      ),
    );
  }
}

class EstrellasVolumen extends StatefulWidget {
  const EstrellasVolumen({
    super.key,
    required this.puntuacion,
    required this.onChanged,
  });

  final int puntuacion;
  final ValueChanged<int> onChanged;

  @override
  State<EstrellasVolumen> createState() => _EstrellasVolumenState();
}

class _EstrellasVolumenState extends State<EstrellasVolumen> with SingleTickerProviderStateMixin {
  late final AnimationController _brillo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _brillo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth.isFinite ? constraints.maxWidth : 280.0;
        final lado = (ancho / 5 * 0.78).clamp(32.0, 68.0).toDouble();
        return SizedBox(
          height: lado,
          child: Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: lado,
                      height: lado,
                      child: _EstrellaVolumen(
                        key: Key('estrella-$i'),
                        dorada: widget.puntuacion > 0 && i <= widget.puntuacion,
                        protagonista: i == widget.puntuacion,
                        brillo: _brillo,
                        onTap: () => widget.onChanged(i),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EstrellaVolumen extends StatelessWidget {
  const _EstrellaVolumen({
    super.key,
    required this.dorada,
    required this.protagonista,
    required this.brillo,
    required this.onTap,
  });

  final bool dorada;
  final bool protagonista;
  final Animation<double> brillo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: dorada ? 0.84 : 1,
        end: protagonista ? 1.12 : (dorada ? 1.06 : 1),
      ),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutBack,
      builder: (context, escala, child) {
        return AnimatedBuilder(
          animation: brillo,
          builder: (context, painted) {
            final pulso = dorada ? 1 + (brillo.value * (protagonista ? 0.05 : 0.02)) : 1.0;
            return Transform.scale(scale: escala * pulso, child: painted);
          },
          child: child,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: CustomPaint(
          painter: _VolumenPainter(dorada: dorada, protagonista: protagonista),
        ),
      ),
    );
  }
}

class _VolumenPainter extends CustomPainter {
  const _VolumenPainter({required this.dorada, required this.protagonista});

  final bool dorada;
  final bool protagonista;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2 + 1);
    final radio = size.shortestSide * 0.4;
    final path = _estrella(centro, radio);
    if (protagonista) {
      canvas.drawCircle(
        centro,
        radio * 1.35,
        Paint()..color = (dorada ? _oro : _cielo).withValues(alpha: 0.45),
      );
    }
    canvas.drawPath(
      path.shift(const Offset(0, 3)),
      Paint()
        ..color = _navy.withValues(alpha: dorada ? 0.18 : 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    final colores = dorada
        ? [_oroClaro, _oro, _oroProfundo]
        : [
            const Color(0xFFF7FBFE).withValues(alpha: 0.9),
            _cielo.withValues(alpha: 0.85),
            const Color(0xFF8FB0C2).withValues(alpha: 0.75),
          ];
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colores,
        ).createShader(Rect.fromCircle(center: centro, radius: radio)),
    );
    canvas.drawPath(
      _estrella(centro.translate(-radio * 0.08, -radio * 0.1), radio * 0.45),
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: dorada ? 0.45 : 0.35),
    );
  }

  Path _estrella(Offset centro, double radio) {
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
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _VolumenPainter oldDelegate) {
    return oldDelegate.dorada != dorada || oldDelegate.protagonista != protagonista;
  }
}

class _FraseCierre extends StatelessWidget {
  const _FraseCierre({required this.puntuacion, required this.compacto});

  final int puntuacion;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final elegida = puntuacion > 0;
    return SizedBox(
      height: compacto ? 42 : 48,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 340),
          switchInCurve: Curves.easeOut,
          child: Text(
            fraseCierre(puntuacion),
            key: ValueKey(puntuacion),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontFamilyFallback: const ['Times New Roman', 'serif'],
              color: elegida ? _navy : _teal,
              fontSize: elegida ? (compacto ? 15 : 18) : 14,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class CartaMomento extends StatelessWidget {
  const CartaMomento({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _beige,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparte tu momento',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontFamilyFallback: ['Times New Roman', 'serif'],
                color: _navy,
                fontSize: 16,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              '¿Qué fue lo que más valoraste de tu experiencia?',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontFamilyFallback: ['Times New Roman', 'serif'],
                fontStyle: FontStyle.italic,
                color: _teal,
                fontSize: 12.5,
                height: 1.2,
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                maxLength: 300,
                maxLines: 2,
                minLines: 1,
                onChanged: (_) => onChanged(),
                cursorColor: _teal,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontFamilyFallback: ['Times New Roman', 'serif'],
                  color: _navy,
                  fontSize: 15,
                  height: 1.25,
                ),
                decoration: const InputDecoration(
                  hintText: 'Escribe aquí...',
                  hintStyle: TextStyle(
                    fontFamily: 'Georgia',
                    fontFamilyFallback: ['Times New Roman', 'serif'],
                    fontStyle: FontStyle.italic,
                    color: _teal,
                    fontSize: 15,
                  ),
                  filled: false,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.only(top: 6),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CierreExperiencia extends StatefulWidget {
  const CierreExperiencia({
    super.key,
    required this.etiqueta,
    required this.onPressed,
    this.cargando = false,
  });

  final String etiqueta;
  final VoidCallback onPressed;
  final bool cargando;

  @override
  State<CierreExperiencia> createState() => _CierreExperienciaState();
}

class _CierreExperienciaState extends State<CierreExperiencia> {
  double _escala = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.cargando ? null : (_) => setState(() => _escala = 0.97),
      onTapCancel: () => setState(() => _escala = 1),
      onTapUp: (_) => setState(() => _escala = 1),
      child: AnimatedScale(
        scale: _escala,
        duration: const Duration(milliseconds: 140),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: FilledButton(
            onPressed: widget.cargando ? null : widget.onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: _beige,
              disabledBackgroundColor: _navy.withValues(alpha: 0.4),
              minimumSize: const Size.fromHeight(50),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: widget.cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _beige),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CustomPaint(
                          painter: _VolumenPainter(dorada: true, protagonista: false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.etiqueta,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontFamilyFallback: ['Times New Roman', 'serif'],
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
