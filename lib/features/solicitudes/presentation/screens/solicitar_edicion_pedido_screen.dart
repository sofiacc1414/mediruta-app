import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../../usuarios/presentation/widgets/main_bottom_bar.dart';
import '../../domain/entities/medicamento.dart';
import '../../domain/entities/solicitud.dart';
import '../providers/solicitud_providers.dart';
import '../widgets/campos_solicitud.dart';

/// HU-07 (ronda 4) — el Paciente pide corregir direcciones,
/// medicamentos y/o la foto de la receta de un pedido ya enviado.
/// Reusa los mismos campos que `NuevaSolicitudScreen` (mismo lenguaje
/// visual, context.md Parte A) — la diferencia es que acá nada se
/// aplica al instante: un Administrador revisa el diff completo y
/// aprueba o rechaza (ver `NovedadesTab` en mediruta-web).
class SolicitarEdicionPedidoScreen extends ConsumerStatefulWidget {
  const SolicitarEdicionPedidoScreen({super.key, required this.solicitud});

  static const routeName = '/solicitudes/solicitar-edicion';

  final Solicitud solicitud;

  @override
  ConsumerState<SolicitarEdicionPedidoScreen> createState() =>
      _SolicitarEdicionPedidoScreenState();
}

class _SolicitarEdicionPedidoScreenState
    extends ConsumerState<SolicitarEdicionPedidoScreen> {
  late final _direccionEntrega = TextEditingController(
    text: widget.solicitud.direccionEntrega ?? '',
  );
  late final _direccionFarmacia = TextEditingController(
    text: widget.solicitud.direccionFarmacia ?? '',
  );
  final _comentario = TextEditingController();

  late final List<Medicamento> _medicamentos = List<Medicamento>.from(
    widget.solicitud.medicamentos,
  );
  bool _medicamentosTocados = false;

  List<int>? _recetaBytesPendiente;
  String? _recetaNombrePendiente;
  String? _recetaContentTypePendiente;

  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _direccionEntrega.dispose();
    _direccionFarmacia.dispose();
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _abrirDialogoMedicamento({int? indice}) async {
    final resultado = await showDialog<Medicamento>(
      context: context,
      builder: (context) => DialogoMedicamento(
        inicial: indice != null ? _medicamentos[indice] : null,
      ),
    );
    if (resultado == null) return;

    setState(() {
      if (indice != null) {
        _medicamentos[indice] = resultado;
      } else {
        _medicamentos.add(resultado);
      }
      _medicamentosTocados = true;
    });
  }

  void _quitarMedicamento(int indice) {
    setState(() {
      _medicamentos.removeAt(indice);
      _medicamentosTocados = true;
    });
  }

  Future<void> _elegirFotoReceta() async {
    final elegido = await mostrarSelectorArchivo(context);
    if (elegido == null) return;

    setState(() {
      _recetaBytesPendiente = elegido.bytes;
      _recetaNombrePendiente = elegido.nombre;
      _recetaContentTypePendiente = elegido.contentType;
    });
  }

  Future<void> _enviar() async {
    final nuevaEntrega = _direccionEntrega.text.trim();
    final nuevaFarmacia = _direccionFarmacia.text.trim();
    final entregaCambio =
        nuevaEntrega.isNotEmpty && nuevaEntrega != (widget.solicitud.direccionEntrega ?? '');
    final farmaciaCambio =
        nuevaFarmacia.isNotEmpty && nuevaFarmacia != (widget.solicitud.direccionFarmacia ?? '');
    final incluyeReceta = _recetaBytesPendiente != null;

    if (!entregaCambio && !farmaciaCambio && !_medicamentosTocados && !incluyeReceta) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indicá al menos un dato para corregir.')),
      );
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final medicamentosNoVacios = _medicamentos.where((m) => !m.estaVacio).toList();
      final novedadId = await ref.read(solicitarEdicionPedidoUseCaseProvider).execute(
            widget.solicitud.id,
            direccionEntrega: entregaCambio ? nuevaEntrega : null,
            direccionFarmacia: farmaciaCambio ? nuevaFarmacia : null,
            detalle: _comentario.text.trim().isEmpty ? null : _comentario.text.trim(),
            medicamentos: _medicamentosTocados ? medicamentosNoVacios : null,
            incluyeReceta: incluyeReceta,
          );

      if (incluyeReceta) {
        await ref.read(adjuntarRecetaPropuestaEdicionUseCaseProvider).execute(
              solicitudId: widget.solicitud.id,
              novedadId: novedadId,
              bytes: _recetaBytesPendiente!,
              nombreArchivo: _recetaNombrePendiente!,
              contentType: _recetaContentTypePendiente!,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu solicitud de corrección fue enviada — el administrador la revisa.'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Pedir corrección de datos',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.navy),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.navy, size: 20),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      bottomNavigationBar: const MainBottomBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  AppErrorBanner(mensaje: _error!),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Un administrador revisa los cambios antes de aplicarlos — cambia solo lo que necesites corregir.',
                  style: TextStyle(color: AppColors.teal, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // ====== DIRECCIONES ======
                const TituloSeccionSolicitud('Farmacia'),
                const SizedBox(height: 12),
                CampoTextoBlanco(
                  label: 'Dirección de la farmacia',
                  icono: Icons.local_pharmacy_outlined,
                  controller: _direccionFarmacia,
                  enabled: !_enviando,
                ),
                const SizedBox(height: 24),
                const TituloSeccionSolicitud('Entrega'),
                const SizedBox(height: 12),
                CampoTextoBlanco(
                  label: 'Dirección de entrega',
                  icono: Icons.home_outlined,
                  controller: _direccionEntrega,
                  enabled: !_enviando,
                ),
                const SizedBox(height: 24),

                // ====== MEDICAMENTOS ======
                const TituloSeccionSolicitud('Medicamentos'),
                const SizedBox(height: 4),
                const Text(
                  'Corrige, quita o agrega una línea por cada medicamento.',
                  style: TextStyle(color: AppColors.teal, fontSize: 13),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _medicamentos.length; i++) ...[
                  FilaResumenMedicamento(
                    medicamento: _medicamentos[i],
                    enabled: !_enviando,
                    onEditar: () => _abrirDialogoMedicamento(indice: i),
                    onQuitar: () => _quitarMedicamento(i),
                  ),
                  const SizedBox(height: 8),
                ],
                Center(
                  child: InkWell(
                    onTap: _enviando ? null : () => _abrirDialogoMedicamento(),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _medicamentos.isEmpty ? 'Agregar medicamento' : 'Agregar otro medicamento',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ====== RECETA ======
                const TituloSeccionSolicitud('Receta médica'),
                const SizedBox(height: 12),
                FilaFotoReceta(
                  tieneArchivo: _recetaBytesPendiente != null || widget.solicitud.recetaUrl != null,
                  bytesLocal: _recetaBytesPendiente,
                  esPdfLocal: _recetaContentTypePendiente == 'application/pdf',
                  urlServidor: _recetaBytesPendiente == null ? widget.solicitud.recetaUrl : null,
                  onElegir: _enviando ? null : _elegirFotoReceta,
                ),
                const SizedBox(height: 24),

                // ====== COMENTARIO ======
                const TituloSeccionSolicitud('Comentario (opcional)'),
                const SizedBox(height: 12),
                CampoTextoBlanco(
                  label: 'Ej.: me mudé de casa',
                  icono: Icons.chat_bubble_outline,
                  controller: _comentario,
                  enabled: !_enviando,
                ),
                const SizedBox(height: 24),

                AppLoadingButton(
                  label: 'Enviar solicitud de corrección',
                  cargando: _enviando,
                  onPressed: _enviar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
