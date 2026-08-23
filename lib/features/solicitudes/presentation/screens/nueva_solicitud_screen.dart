import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_icon_badge.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../usuarios/presentation/providers/perfil_providers.dart';
import '../../domain/entities/datos_solicitud.dart';
import '../providers/solicitud_providers.dart';

/// G01/G04 — HU-03. Crear una solicitud nueva (`solicitudId == null`,
/// borrador guardado solo en el dispositivo hasta confirmar — nada viaja
/// a la API mientras se completa) o editar una ya existente en Borrador
/// (`solicitudId != null`, carga y guarda directo contra la API).
class NuevaSolicitudScreen extends ConsumerStatefulWidget {
  const NuevaSolicitudScreen({super.key, this.solicitudId});

  static const routeName = '/solicitudes/nueva';

  final String? solicitudId;

  @override
  ConsumerState<NuevaSolicitudScreen> createState() => _NuevaSolicitudScreenState();
}

class _NuevaSolicitudScreenState extends ConsumerState<NuevaSolicitudScreen> {
  final _medicamentoNombre = TextEditingController();
  final _medicamentoConcentracion = TextEditingController();
  final _medicamentoFormaFarmaceutica = TextEditingController();
  final _medicamentoCantidad = TextEditingController();
  final _medicamentoPosologia = TextEditingController();
  final _recetaMedicoNombre = TextEditingController();
  final _recetaMedicoRegistro = TextEditingController();
  final _recetaIps = TextEditingController();
  final _direccionEntrega = TextEditingController();
  DateTime? _recetaFechaExpedicion;

  bool get _editandoExistente => widget.solicitudId != null;
  String? _solicitudIdRemoto;
  DatosSolicitud? _datosOriginales;

  bool _cargandoInicial = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _solicitudIdRemoto = widget.solicitudId;
    _inicializar();
    for (final controller in _controllers) {
      controller.addListener(_onCambioCampo);
    }
  }

  List<TextEditingController> get _controllers => [
    _medicamentoNombre,
    _medicamentoConcentracion,
    _medicamentoFormaFarmaceutica,
    _medicamentoCantidad,
    _medicamentoPosologia,
    _recetaMedicoNombre,
    _recetaMedicoRegistro,
    _recetaIps,
    _direccionEntrega,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _inicializar() async {
    if (_editandoExistente) {
      try {
        final solicitud = await ref
            .read(obtenerSolicitudUseCaseProvider)
            .execute(widget.solicitudId!);
        _rellenar(solicitud.datos);
        _datosOriginales = solicitud.datos;
      } on ApiException catch (error) {
        setState(() => _error = error.message);
      } on ApiSinConexionException catch (error) {
        setState(() => _error = error.toString());
      }
    } else {
      final borrador = await ref.read(borradorLocalRepositoryProvider).leer();
      if (borrador != null) {
        _rellenar(borrador);
      } else {
        // Best-effort: precarga la dirección del perfil (HU-02). Si
        // falla, el paciente igual puede escribirla a mano.
        try {
          final perfil = await ref.read(obtenerPerfilUseCaseProvider).execute();
          _direccionEntrega.text = perfil.paciente?.direccion ?? '';
        } catch (_) {
          // no crítico
        }
      }
    }
    if (mounted) setState(() => _cargandoInicial = false);
  }

  void _rellenar(DatosSolicitud datos) {
    _medicamentoNombre.text = datos.medicamentoNombre ?? '';
    _medicamentoConcentracion.text = datos.medicamentoConcentracion ?? '';
    _medicamentoFormaFarmaceutica.text = datos.medicamentoFormaFarmaceutica ?? '';
    _medicamentoCantidad.text = datos.medicamentoCantidad ?? '';
    _medicamentoPosologia.text = datos.medicamentoPosologia ?? '';
    _recetaMedicoNombre.text = datos.recetaMedicoNombre ?? '';
    _recetaMedicoRegistro.text = datos.recetaMedicoRegistro ?? '';
    _recetaIps.text = datos.recetaIps ?? '';
    _direccionEntrega.text = datos.direccionEntrega ?? '';
    if (datos.recetaFechaExpedicion != null) {
      _recetaFechaExpedicion = DateTime.tryParse(datos.recetaFechaExpedicion!);
    }
  }

  DatosSolicitud _datosActuales() {
    return DatosSolicitud(
      medicamentoNombre: _vacioComoNulo(_medicamentoNombre.text),
      medicamentoConcentracion: _vacioComoNulo(_medicamentoConcentracion.text),
      medicamentoFormaFarmaceutica: _vacioComoNulo(_medicamentoFormaFarmaceutica.text),
      medicamentoCantidad: _vacioComoNulo(_medicamentoCantidad.text),
      medicamentoPosologia: _vacioComoNulo(_medicamentoPosologia.text),
      recetaMedicoNombre: _vacioComoNulo(_recetaMedicoNombre.text),
      recetaMedicoRegistro: _vacioComoNulo(_recetaMedicoRegistro.text),
      recetaIps: _vacioComoNulo(_recetaIps.text),
      recetaFechaExpedicion: _recetaFechaExpedicion != null ? _isoFecha(_recetaFechaExpedicion!) : null,
      direccionEntrega: _vacioComoNulo(_direccionEntrega.text),
    );
  }

  String? _vacioComoNulo(String texto) => texto.trim().isEmpty ? null : texto.trim();

  /// Mientras se crea (no edita), cada cambio se guarda solo en el
  /// dispositivo — nunca en la API — para que sobreviva aunque cierren
  /// la app de golpe, sin gastar red/BD mientras se está escribiendo.
  void _onCambioCampo() {
    if (_editandoExistente || _cargandoInicial) return;
    ref.read(borradorLocalRepositoryProvider).guardar(_datosActuales());
  }

  bool _huboCambiosSinGuardar() {
    if (!_editandoExistente) {
      return _datosActuales().toJson().values.any((v) => v != null);
    }
    final actuales = _datosActuales();
    final originales = _datosOriginales;
    return originales == null || actuales.toJson().toString() != originales.toJson().toString();
  }

  /// Crea (si es nueva) o actualiza (si ya existe) con los valores
  /// actuales. Devuelve el id remoto. Único punto donde esta pantalla
  /// habla con la API para persistir datos.
  Future<String> _persistir() async {
    final datos = _datosActuales();
    if (_solicitudIdRemoto == null) {
      final id = await ref.read(crearSolicitudUseCaseProvider).execute(datos);
      _solicitudIdRemoto = id;
      await ref.read(borradorLocalRepositoryProvider).limpiar();
      return id;
    }
    await ref.read(actualizarSolicitudUseCaseProvider).execute(_solicitudIdRemoto!, datos);
    return _solicitudIdRemoto!;
  }

  Future<void> _onGuardarBorrador() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await _persistir();
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _onEnviar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final id = await _persistir();
      await ref.read(enviarSolicitudUseCaseProvider).execute(id);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<bool> _confirmarSalida() async {
    if (!_huboCambiosSinGuardar()) return true;

    if (_editandoExistente) {
      final decision = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Cambios sin guardar'),
          content: const Text('¿Guardás los cambios antes de salir?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Seguir editando'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Descartar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
      if (decision == null) return false;
      if (decision) await _persistir();
      return true;
    }

    final decision = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¿Continuar con este pedido más tarde?'),
        content: const Text(
          'Podés guardar lo que ya cargaste para retomarlo después, o descartarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Seguir editando'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Descartar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar para después'),
          ),
        ],
      ),
    );
    if (decision == null) return false;
    if (decision) {
      await _persistir();
    } else {
      await ref.read(borradorLocalRepositoryProvider).limpiar();
    }
    return true;
  }

  Future<void> _elegirFechaReceta() async {
    final ahora = DateTime.now();
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _recetaFechaExpedicion ?? ahora,
      firstDate: DateTime(ahora.year - 2),
      lastDate: ahora,
    );
    if (seleccionada != null) {
      setState(() => _recetaFechaExpedicion = seleccionada);
      _onCambioCampo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final faltantes = _datosActuales().calcularFaltantes();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final debeSalir = await _confirmarSalida();
        if (debeSalir && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editandoExistente ? 'Editar solicitud' : 'Nueva solicitud'),
        ),
        body: _cargandoInicial
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: AppIconBadge(icono: Icons.medication_outlined),
                        ),
                        const SizedBox(height: 20),
                        if (_error != null) ...[
                          AppErrorBanner(mensaje: _error!),
                          const SizedBox(height: 16),
                        ],
                        const _TituloSeccion('Medicamento'),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Nombre del medicamento',
                          icono: Icons.medication_outlined,
                          controller: _medicamentoNombre,
                          enabled: !_guardando,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Concentración/dosis',
                          icono: Icons.science_outlined,
                          controller: _medicamentoConcentracion,
                          enabled: !_guardando,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Forma farmacéutica',
                          icono: Icons.category_outlined,
                          controller: _medicamentoFormaFarmaceutica,
                          enabled: !_guardando,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Cantidad solicitada',
                          icono: Icons.numbers_outlined,
                          controller: _medicamentoCantidad,
                          enabled: !_guardando,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Posología / indicaciones de uso',
                          icono: Icons.schedule_outlined,
                          controller: _medicamentoPosologia,
                          enabled: !_guardando,
                        ),
                        const SizedBox(height: 24),
                        const _TituloSeccion('Receta médica'),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Nombre del médico',
                          icono: Icons.badge_outlined,
                          controller: _recetaMedicoNombre,
                          enabled: !_guardando,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Registro médico',
                          icono: Icons.assignment_ind_outlined,
                          controller: _recetaMedicoRegistro,
                          enabled: !_guardando,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'IPS que expide la receta',
                          icono: Icons.local_hospital_outlined,
                          controller: _recetaIps,
                          enabled: !_guardando,
                        ),
                        const SizedBox(height: 12),
                        _CampoFecha(
                          label: 'Fecha de expedición de la receta',
                          fecha: _recetaFechaExpedicion,
                          onTap: _guardando ? null : _elegirFechaReceta,
                        ),
                        const SizedBox(height: 24),
                        const _TituloSeccion('Entrega'),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Dirección de entrega',
                          icono: Icons.home_outlined,
                          controller: _direccionEntrega,
                          enabled: !_guardando,
                        ),
                        const SizedBox(height: 24),
                        AppLoadingButton(
                          label: 'Guardar borrador',
                          variante: AppButtonVariante.secondary,
                          cargando: _guardando,
                          onPressed: _onGuardarBorrador,
                        ),
                        const SizedBox(height: 8),
                        AppLoadingButton(
                          label: 'Enviar solicitud',
                          cargando: _guardando,
                          onPressed: faltantes.isEmpty ? _onEnviar : null,
                        ),
                        if (faltantes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Para enviar falta: ${faltantes.join(', ')}.',
                            style: const TextStyle(color: AppColors.teal, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 16),
    );
  }
}

class _CampoFecha extends StatelessWidget {
  const _CampoFecha({required this.label, required this.fecha, required this.onTap});

  final String label;
  final DateTime? fecha;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined, color: AppColors.teal),
          filled: true,
          fillColor: AppColors.beige,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        child: Text(fecha != null ? _isoFecha(fecha!) : 'Selecciona una fecha'),
      ),
    );
  }
}

String _isoFecha(DateTime fecha) {
  final anio = fecha.year.toString().padLeft(4, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final dia = fecha.day.toString().padLeft(2, '0');
  return '$anio-$mes-$dia';
}
