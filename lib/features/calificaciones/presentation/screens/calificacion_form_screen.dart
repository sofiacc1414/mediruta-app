import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../domain/entities/calificacion.dart';
import '../providers/calificacion_providers.dart';
import '../widgets/aviso_calificacion.dart';
import '../widgets/experiencia_cierre_visual.dart';
import 'calificacion_confirmacion_screen.dart';

class CalificacionFormArgs {
  const CalificacionFormArgs({
    required this.pedidoId,
    required this.codigoPedido,
    required this.estadoPedido,
    required this.editar,
  });

  final String pedidoId;
  final String? codigoPedido;
  final String estadoPedido;
  final bool editar;
}

/// Pantallas 2 y 5 — crear o editar la calificación, más los bloqueos de G05.
class CalificacionFormScreen extends ConsumerStatefulWidget {
  const CalificacionFormScreen({super.key, required this.args});

  static const routeName = '/pedidos-calificacion/form';

  final CalificacionFormArgs args;

  @override
  ConsumerState<CalificacionFormScreen> createState() => _CalificacionFormScreenState();
}

class _CalificacionFormScreenState extends ConsumerState<CalificacionFormScreen>
    with SingleTickerProviderStateMixin {
  final _comentario = TextEditingController();
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();
  int _puntuacion = 0;
  bool _cargando = false;
  bool _enviando = false;
  String? _error;
  String? _bloqueo;

  @override
  void initState() {
    super.initState();
    if (widget.args.estadoPedido != 'entregado') {
      _bloqueo = 'no_entregado';
    } else if (widget.args.editar) {
      _cargar();
    }
  }

  @override
  void dispose() {
    _entrada.dispose();
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final calificacion =
          await ref.read(consultarCalificacionUseCaseProvider).execute(widget.args.pedidoId);
      if (!mounted) return;
      _puntuacion = calificacion.puntuacion;
      _comentario.text = calificacion.comentario ?? '';
    } on ApiException catch (error) {
      _aplicarError(error);
    } on ApiSinConexionException catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _aplicarError(ApiException error) {
    final texto = error.message;
    if (texto.contains('Aún no puedes calificar')) {
      _bloqueo = 'no_entregado';
    } else if (texto.contains('No puedes calificar') || texto.contains('permiso')) {
      _bloqueo = 'ajeno';
    } else {
      _error = texto;
    }
  }

  Future<void> _enviar() async {
    if (_puntuacion < 1) {
      setState(() => _error = 'Selecciona una puntuación para continuar.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final comentario = _comentario.text.trim();
      final Calificacion calificacion;
      if (widget.args.editar) {
        calificacion = await ref.read(actualizarCalificacionUseCaseProvider).execute(
          pedidoId: widget.args.pedidoId,
          puntuacion: _puntuacion,
          comentario: comentario,
        );
      } else {
        calificacion = await ref.read(crearCalificacionUseCaseProvider).execute(
          pedidoId: widget.args.pedidoId,
          puntuacion: _puntuacion,
          comentario: comentario,
        );
      }
      if (!mounted) return;
      if (widget.args.editar) {
        Navigator.of(context).pop(calificacion);
        return;
      }
      await Navigator.of(context).pushReplacementNamed(
        CalificacionConfirmacionScreen.routeName,
        arguments: widget.args.pedidoId,
      );
    } on ApiException catch (error) {
      setState(() => _aplicarError(error));
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _retirar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.beige,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¿Quieres retirar tu experiencia?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontFamilyFallback: ['Times New Roman', 'serif'],
                  color: AppColors.navy,
                  fontSize: 22,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tu valoración será retirada, pero conservaremos la información mínima necesaria para auditoría.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.teal, height: 1.4, fontSize: 15),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text(
                        'Retirar experiencia',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _enviando = true);
    try {
      await ref.read(retirarCalificacionUseCaseProvider).execute(widget.args.pedidoId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: AppColors.beige,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Calificación retirada',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontFamilyFallback: ['Times New Roman', 'serif'],
                    color: AppColors.navy,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tu calificación ha sido eliminada correctamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.teal, height: 1.4),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editar = widget.args.editar;
    final curva = CurvedAnimation(parent: _entrada, curve: Curves.easeOutCubic);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5EFEB),
      body: ExperienciaFondo(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : FadeTransition(
                opacity: curva,
                child: SafeArea(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 4, 22, 10),
                        child: _bloqueo != null
                            ? _bloqueoVista()
                            : EscenaExperiencia(
                                editar: editar,
                                puntuacion: _puntuacion,
                                onPuntuacion: (valor) => setState(() => _puntuacion = valor),
                                comentario: _comentario,
                                onComentario: () => setState(() {}),
                                onEnviar: _enviar,
                                onRetirar: editar ? _retirar : null,
                                enviando: _enviando,
                                error: _error,
                              ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _bloqueoVista() {
    final aviso = _bloqueo == 'ajeno'
        ? const AvisoCalificacion(
            icono: Icons.person_off_outlined,
            titulo: 'No puedes calificar este pedido',
            explicacion: 'No tienes permiso para realizar esta acción.',
          )
        : const AvisoCalificacion(
            icono: Icons.lock_outline,
            titulo: 'Aún no puedes calificar este pedido',
            explicacion: 'Solo puedes calificar cuando el pedido haya sido entregado.',
          );
    return Column(
      children: [
        const Spacer(),
        aviso,
        const Spacer(),
      ],
    );
  }
}
