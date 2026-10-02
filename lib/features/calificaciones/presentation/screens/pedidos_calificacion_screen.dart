import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../usuarios/presentation/widgets/main_bottom_bar.dart';
import '../../domain/entities/calificacion.dart';
import '../providers/calificacion_providers.dart';
import '../widgets/experiencia_cierre_visual.dart';
import 'calificacion_form_screen.dart';

/// Pantalla 1 — pedidos del paciente, con filtro Entregados y acceso a calificar.
class PedidosCalificacionScreen extends ConsumerStatefulWidget {
  const PedidosCalificacionScreen({super.key});

  static const routeName = '/pedidos-calificacion';

  @override
  ConsumerState<PedidosCalificacionScreen> createState() =>
      _PedidosCalificacionScreenState();
}

class _PedidosCalificacionScreenState extends ConsumerState<PedidosCalificacionScreen> {
  static const _enProceso = {
    'pendiente_revision',
    'en_asignacion',
    'asignado_en_camino_farmacia',
    'medicamentos_recogidos',
    'en_camino_entrega',
    'en_sitio',
    'en_farmacia',
  };

  bool _cargando = true;
  String? _error;
  List<PedidoCalificacion> _pedidos = const [];
  int _tab = 2;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final pedidos = await ref.read(listarPedidosCalificacionUseCaseProvider).execute();
      if (!mounted) return;
      setState(() => _pedidos = pedidos);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<PedidoCalificacion> get _visibles {
    return switch (_tab) {
      1 => _pedidos.where((p) => _enProceso.contains(p.estado)).toList(),
      2 => _pedidos.where((p) => p.estado == 'entregado').toList(),
      _ => _pedidos,
    };
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _visibles;
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFEB),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.navy,
      ),
      bottomNavigationBar: const MainBottomBar(),
      body: ExperienciaFondo(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : RefreshIndicator(
                onRefresh: _cargar,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 56, 20, 24),
                  children: [
                    const Text(
                      '¿Qué entrega quieres valorar?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontFamilyFallback: ['Times New Roman', 'serif'],
                        color: AppColors.navy,
                        fontSize: 28,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Comparte cómo fue tu experiencia con MediRuta',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.teal, height: 1.35, fontSize: 15),
                    ),
                    const SizedBox(height: 18),
                    _Tabs(
                      seleccionado: _tab,
                      onChanged: (tab) => setState(() => _tab = tab),
                    ),
                    const SizedBox(height: 18),
                    if (_error != null) AppErrorBanner(mensaje: _error!),
                    if (visibles.isEmpty && _error == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Text(
                          'Todavía no hay un momento para compartir aquí.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.teal, height: 1.4),
                        ),
                      ),
                    for (final pedido in visibles) ...[
                      _TarjetaPedido(
                        pedido: pedido,
                        onCalificar: () => _abrir(pedido, editar: false),
                        onVer: () => _abrir(pedido, editar: true),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _abrir(PedidoCalificacion pedido, {required bool editar}) async {
    await Navigator.of(context).pushNamed(
      CalificacionFormScreen.routeName,
      arguments: CalificacionFormArgs(
        pedidoId: pedido.id,
        codigoPedido: pedido.codigoPedido,
        estadoPedido: pedido.estado,
        editar: editar,
      ),
    );
    if (mounted) _cargar();
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.seleccionado, required this.onChanged});

  final int seleccionado;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const etiquetas = ['Todos', 'En proceso', 'Entregados'];
    return Row(
      children: [
        for (var i = 0; i < etiquetas.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: seleccionado == i ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: seleccionado == i
                      ? [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  etiquetas[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontFamilyFallback: const ['Times New Roman', 'serif'],
                    color: seleccionado == i ? AppColors.navy : AppColors.teal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TarjetaPedido extends StatelessWidget {
  const _TarjetaPedido({
    required this.pedido,
    required this.onCalificar,
    required this.onVer,
  });

  final PedidoCalificacion pedido;
  final VoidCallback onCalificar;
  final VoidCallback onVer;

  @override
  Widget build(BuildContext context) {
    final entregado = pedido.estado == 'entregado';
    final codigo = pedido.codigoPedido ?? 'Pedido';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/images/hero_medicamentos.png',
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido $codigo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontFamilyFallback: ['Times New Roman', 'serif'],
                        color: AppColors.navy,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entregado ? 'Entregada' : _estadoHumano(pedido.estado),
                      style: const TextStyle(color: AppColors.navy, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fecha(pedido.creadoEn),
                      style: const TextStyle(color: AppColors.teal, fontSize: 13),
                    ),
                    if (pedido.cantidadMedicamentos > 0)
                      Text(
                        pedido.cantidadMedicamentos == 1
                            ? '1 medicamento'
                            : '${pedido.cantidadMedicamentos} medicamentos',
                        style: const TextStyle(color: AppColors.teal, fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (entregado) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: pedido.tieneCalificacionActiva ? onVer : onCalificar,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.beige,
                  minimumSize: const Size.fromHeight(48),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: Text(
                  pedido.tieneCalificacionActiva ? 'Ver experiencia' : 'Compartir experiencia',
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontFamilyFallback: ['Times New Roman', 'serif'],
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _estadoHumano(String estado) {
  return switch (estado) {
    'pendiente_revision' => 'En revisión',
    'en_asignacion' => 'En asignación',
    'asignado_en_camino_farmacia' => 'En camino a la farmacia',
    'en_farmacia' => 'En la farmacia',
    'medicamentos_recogidos' => 'Medicamentos recogidos',
    'en_camino_entrega' => 'En camino',
    'en_sitio' => 'En el lugar',
    'entregado' => 'Entregada',
    'cancelada' => 'Cancelada',
    _ => 'En proceso',
  };
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
