import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_image_viewer.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../../usuarios/presentation/providers/perfil_providers.dart';
import '../../../usuarios/presentation/widgets/main_bottom_bar.dart';
import '../../domain/entities/datos_solicitud.dart';
import '../../domain/entities/medicamento.dart';
import '../providers/solicitud_providers.dart';

/// G01/G04 — HU-03. Crear una solicitud nueva o editar una existente en Borrador.
class NuevaSolicitudScreen extends ConsumerStatefulWidget {
  const NuevaSolicitudScreen({super.key, this.solicitudId});

  static const routeName = '/solicitudes/nueva';

  final String? solicitudId;

  @override
  ConsumerState<NuevaSolicitudScreen> createState() => _NuevaSolicitudScreenState();
}

String? _vacioComoNulo(String texto) => texto.trim().isEmpty ? null : texto.trim();

class _NuevaSolicitudScreenState extends ConsumerState<NuevaSolicitudScreen> {
  final List<Medicamento> _medicamentos = [];
  final _direccionEntrega = TextEditingController();
  final _direccionFarmacia = TextEditingController();
  DateTime? _recetaFechaVencimiento;

  String? _recetaUrlServidor;
  List<int>? _recetaBytesPendiente;
  String? _recetaNombrePendiente;
  String? _recetaContentTypePendiente;

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
    _direccionEntrega.addListener(_onCambioCampo);
    _direccionFarmacia.addListener(_onCambioCampo);
    _inicializar();
  }

  @override
  void dispose() {
    _direccionEntrega.dispose();
    _direccionFarmacia.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    if (_editandoExistente) {
      try {
        final solicitud = await ref
            .read(obtenerSolicitudUseCaseProvider)
            .execute(widget.solicitudId!);
        final datos = DatosSolicitud(
          medicamentos: solicitud.medicamentos,
          recetaFechaVencimiento: solicitud.recetaFechaVencimiento,
          direccionEntrega: solicitud.direccionEntrega,
          direccionFarmacia: solicitud.direccionFarmacia,
        );
        _rellenar(datos);
        _recetaUrlServidor = solicitud.recetaUrl;
        _datosOriginales = datos;
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
        try {
          final perfil = await ref.read(obtenerPerfilUseCaseProvider).execute();
          _direccionEntrega.text = perfil.paciente?.direccion ?? '';
        } catch (_) {}
      }
    }

    if (mounted) setState(() => _cargandoInicial = false);
  }

  void _rellenar(DatosSolicitud datos) {
    _medicamentos.addAll(datos.medicamentos);
    _direccionEntrega.text = datos.direccionEntrega ?? '';
    _direccionFarmacia.text = datos.direccionFarmacia ?? '';
    if (datos.recetaFechaVencimiento != null) {
      _recetaFechaVencimiento = DateTime.tryParse(datos.recetaFechaVencimiento!);
    }
  }

  Future<void> _abrirDialogoMedicamento({int? indice}) async {
    final resultado = await showDialog<Medicamento>(
      context: context,
      builder: (context) => _DialogoMedicamento(
        inicial: indice != null ? _medicamentos[indice] : null,
      ),
    );
    if (resultado == null) return;

    setState(() {
      if (indice != null) {
        _medicamentos[indice] = resultado;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Medicamento editado exitosamente',
              style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            elevation: 4,
          ),
        );
      } else {
        _medicamentos.add(resultado);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Medicamento registrado con éxito',
              style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            elevation: 4,
          ),
        );
      }
    });
    _onCambioCampo();
  }

  void _quitarMedicamento(int indice) {
    setState(() => _medicamentos.removeAt(indice));
    _onCambioCampo();
  }

  DatosSolicitud _datosActuales() {
    return DatosSolicitud(
      medicamentos: List<Medicamento>.from(_medicamentos),
      recetaFechaVencimiento: _recetaFechaVencimiento != null ? _isoFecha(_recetaFechaVencimiento!) : null,
      direccionEntrega: _vacioComoNulo(_direccionEntrega.text),
      direccionFarmacia: _vacioComoNulo(_direccionFarmacia.text),
    );
  }

  void _onCambioCampo() {
    if (_editandoExistente || _cargandoInicial) return;
    ref.read(borradorLocalRepositoryProvider).guardar(_datosActuales());
  }

  bool _huboCambiosSinGuardar() {
    final hayRecetaPendiente = _recetaBytesPendiente != null;
    if (!_editandoExistente) {
      final datos = _datosActuales();
      final hayMedicamento = datos.medicamentos.any((m) => !m.estaVacio);
      return hayMedicamento ||
          hayRecetaPendiente ||
          datos.recetaFechaVencimiento != null ||
          datos.direccionEntrega != null ||
          datos.direccionFarmacia != null;
    }
    final actuales = _datosActuales();
    final originales = _datosOriginales;
    return hayRecetaPendiente ||
        originales == null ||
        actuales.toJson().toString() != originales.toJson().toString();
  }

  Future<String> _persistir() async {
    final datos = _datosActuales();
    String id;
    if (_solicitudIdRemoto == null) {
      id = await ref.read(crearSolicitudUseCaseProvider).execute(datos);
      _solicitudIdRemoto = id;
      await ref.read(borradorLocalRepositoryProvider).limpiar();
    } else {
      id = _solicitudIdRemoto!;
      await ref.read(actualizarSolicitudUseCaseProvider).execute(id, datos);
    }

    if (_recetaBytesPendiente != null) {
      await ref
          .read(subirRecetaUseCaseProvider)
          .execute(
            solicitudId: id,
            bytes: _recetaBytesPendiente!,
            nombreArchivo: _recetaNombrePendiente!,
            contentType: _recetaContentTypePendiente!,
          );
      _recetaBytesPendiente = null;
    }

    return id;
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
      final codigoPedido = await ref.read(enviarSolicitudUseCaseProvider).execute(id);
      if (mounted) await _mostrarPedidoConfirmado(codigoPedido);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _mostrarPedidoConfirmado(String codigoPedido) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '¡Tu solicitud fue exitosa!',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Guarda este código de pedido:'),
            const SizedBox(height: 12),
            Text(
              codigoPedido,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendido', style: TextStyle(color: AppColors.navy)),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmarSalida() async {
    if (!_huboCambiosSinGuardar()) return true;

    if (_editandoExistente) {
      final decision = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cambios sin guardar'),
          content: const Text('¿Guardás los cambios antes de salir?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Seguir editando', style: TextStyle(color: AppColors.navy)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Descartar', style: TextStyle(color: AppColors.navy)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar', style: TextStyle(color: AppColors.teal)),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Continuar con este pedido más tarde?'),
        content: const Text(
          'Podés guardar lo que ya cargaste para retomarlo después, o descartarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Seguir editando', style: TextStyle(color: AppColors.navy)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Descartar', style: TextStyle(color: AppColors.navy)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar para después', style: TextStyle(color: AppColors.teal)),
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
      initialDate: _recetaFechaVencimiento ?? ahora,
      firstDate: DateTime(ahora.year - 2),
      lastDate: DateTime(ahora.year + 5),
    );
    if (seleccionada != null) {
      setState(() => _recetaFechaVencimiento = seleccionada);
      _onCambioCampo();
    }
  }

  Future<void> _elegirFotoReceta() async {
    final origen = await showModalBottomSheet<_OrigenArchivo>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.teal),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(context).pop(_OrigenArchivo.camara),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.teal),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(context).pop(_OrigenArchivo.galeria),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.teal),
              title: const Text('Elegir PDF'),
              onTap: () => Navigator.of(context).pop(_OrigenArchivo.pdf),
            ),
          ],
        ),
      ),
    );
    if (origen == null) return;

    List<int>? bytes;
    String? nombre;
    String contentType = 'image/jpeg';

    if (origen == _OrigenArchivo.pdf) {
      final archivo = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['pdf']);
      if (archivo == null) return;
      bytes = await archivo.readAsBytes();
      nombre = archivo.name;
      contentType = 'application/pdf';
    } else {
      final archivo = await ImagePicker().pickImage(
        source: origen == _OrigenArchivo.camara ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );
      if (archivo == null) return;
      bytes = await archivo.readAsBytes();
      nombre = archivo.name;
      contentType = nombre.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    }

    setState(() {
      _recetaBytesPendiente = bytes;
      _recetaNombrePendiente = nombre;
      _recetaContentTypePendiente = contentType;
    });
    _onCambioCampo();
  }

  @override
  Widget build(BuildContext context) {
    final datosActuales = _datosActuales();
    final faltantes = datosActuales.calcularFaltantes(
      tieneRecetaSubida: _recetaBytesPendiente != null || _recetaUrlServidor != null,
    );

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
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Nueva solicitud',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.navy,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.navy, size: 20),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
          ),
        ),
        bottomNavigationBar: const MainBottomBar(),
        body: _cargandoInicial
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ====== IMAGEN SOLA ======
                        Align(
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/hero_medicamentos.png',
                            height: 180,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.medication_outlined,
                              color: AppColors.navy,
                              size: 60,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_error != null) ...[
                          AppErrorBanner(mensaje: _error!),
                          const SizedBox(height: 16),
                        ],

                        // ====== SECCIÓN: MEDICAMENTOS ======
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Medicamentos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Una fórmula puede traer más de uno',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.teal, fontSize: 13),
                              ),
                              const Text(
                                'Agrega una línea por cada uno',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.teal, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              // Botón gris claro con letra azul oscuro
                              Center(
                                child: InkWell(
                                  onTap: _guardando ? null : () => _abrirDialogoMedicamento(),
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ====== SECCIÓN: RECETA ======
                        const _TituloSeccion('Receta médica'),
                        const SizedBox(height: 12),
                        _FilaFotoReceta(
                          tieneArchivo: _recetaBytesPendiente != null || _recetaUrlServidor != null,
                          bytesLocal: _recetaBytesPendiente,
                          esPdfLocal: _recetaContentTypePendiente == 'application/pdf',
                          urlServidor: _recetaUrlServidor,
                          onElegir: _guardando ? null : _elegirFotoReceta,
                        ),
                        const SizedBox(height: 12),
                        _CampoFecha(
                          label: 'Fecha de vencimiento de la receta',
                          fecha: _recetaFechaVencimiento,
                          onTap: _guardando ? null : _elegirFechaReceta,
                        ),
                        const SizedBox(height: 24),

                        // ====== SECCIÓN: FARMACIA ======
                        const _TituloSeccion('Farmacia'),
                        const SizedBox(height: 4),
                        const Text(
                          'Dónde el domiciliario retira el medicamento.',
                          style: TextStyle(color: AppColors.teal, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        _CampoTextoBlanco(
                          label: 'Dirección de la farmacia',
                          icono: Icons.local_pharmacy_outlined,
                          controller: _direccionFarmacia,
                          enabled: !_guardando,
                        ),
                        const SizedBox(height: 24),

                        // ====== SECCIÓN: ENTREGA ======
                        const _TituloSeccion('Entrega'),
                        const SizedBox(height: 12),
                        _CampoTextoBlanco(
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

enum _OrigenArchivo { camara, galeria, pdf }

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

// ====== CAMPO BLANCO CON BORDE GRIS ======
class _CampoTextoBlanco extends StatelessWidget {
  const _CampoTextoBlanco({
    required this.label,
    required this.icono,
    required this.controller,
    required this.enabled,
  });

  final String label;
  final IconData icono;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.navy,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icono, color: AppColors.teal, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

const List<String> _formasFarmaceuticasSugeridas = [
  'Tableta',
  'Tableta recubierta',
  'Cápsula',
  'Cápsula blanda',
  'Jarabe',
  'Suspensión oral',
  'Solución oral',
  'Gotas orales',
  'Gotas oftálmicas',
  'Gotas óticas',
  'Solución inyectable',
  'Ampolla',
  'Vial',
  'Crema',
  'Ungüento',
  'Pomada',
  'Gel',
  'Loción',
  'Champú',
  'Parche transdérmico',
  'Supositorio',
  'Óvulo vaginal',
  'Inhalador',
  'Spray nasal',
  'Polvo para reconstituir',
  'Sobre',
  'Frasco',
];

// ====== CAMPO DE FORMA FARMACÉUTICA CON AUTOCOMPLETADO ======
class _CampoFormaFarmaceutica extends StatefulWidget {
  const _CampoFormaFarmaceutica({required this.controller});

  final TextEditingController controller;

  @override
  State<_CampoFormaFarmaceutica> createState() => _CampoFormaFarmaceuticaState();
}

class _CampoFormaFarmaceuticaState extends State<_CampoFormaFarmaceutica> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  List<String> _sugerencias = [];
  bool _mostrarSugerencias = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextoCambiado);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextoCambiado);
    _focusNode.dispose();
    _ocultarSugerencias();
    super.dispose();
  }

  void _onTextoCambiado() {
    final texto = widget.controller.text.toLowerCase().trim();
    if (texto.isEmpty) {
      setState(() {
        _sugerencias = [];
        _mostrarSugerencias = false;
      });
      _ocultarSugerencias();
      return;
    }

    final sugerencias = _formasFarmaceuticasSugeridas
        .where((opcion) => opcion.toLowerCase().contains(texto))
        .toList();

    if (sugerencias.isEmpty) {
      _ocultarSugerencias();
      setState(() {
        _sugerencias = [];
        _mostrarSugerencias = false;
      });
    } else {
      setState(() {
        _sugerencias = sugerencias;
        _mostrarSugerencias = true;
      });
      _mostrarOverlay();
    }
  }

  void _mostrarOverlay() {
    _ocultarSugerencias();
    if (!mounted) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _sugerencias.length,
                itemBuilder: (context, index) {
                  final sugerencia = _sugerencias[index];
                  return ListTile(
                    title: Text(
                      sugerencia,
                      style: const TextStyle(color: AppColors.navy, fontSize: 14),
                    ),
                    onTap: () {
                      widget.controller.text = sugerencia;
                      setState(() {
                        _sugerencias = [];
                        _mostrarSugerencias = false;
                      });
                      _ocultarSugerencias();
                      _focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _ocultarSugerencias() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Icon(Icons.medication_outlined, color: AppColors.teal, size: 20),
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                style: const TextStyle(color: AppColors.navy, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Forma farmacéutica (Obligatorio)',
                  hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                onTap: () {
                  if (widget.controller.text.isNotEmpty) {
                    _onTextoCambiado();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogoMedicamento extends StatefulWidget {
  const _DialogoMedicamento({this.inicial});

  final Medicamento? inicial;

  @override
  State<_DialogoMedicamento> createState() => _DialogoMedicamentoState();
}

class _DialogoMedicamentoState extends State<_DialogoMedicamento> {
  late final _nombre = TextEditingController(text: widget.inicial?.nombre ?? '');
  late final _concentracion = TextEditingController(text: widget.inicial?.concentracion ?? '');
  late final _formaFarmaceutica = TextEditingController(
    text: widget.inicial?.formaFarmaceutica ?? '',
  );
  late final _cantidad = TextEditingController(text: widget.inicial?.cantidad ?? '');
  late final _posologia = TextEditingController(text: widget.inicial?.posologia ?? '');

  bool get _datosCompletos =>
      _nombre.text.trim().isNotEmpty &&
      _concentracion.text.trim().isNotEmpty &&
      _formaFarmaceutica.text.trim().isNotEmpty &&
      _cantidad.text.trim().isNotEmpty;

  @override
  void dispose() {
    _nombre.dispose();
    _concentracion.dispose();
    _formaFarmaceutica.dispose();
    _cantidad.dispose();
    _posologia.dispose();
    super.dispose();
  }

  void _aceptar() {
    Navigator.of(context).pop(
      Medicamento(
        nombre: _vacioComoNulo(_nombre.text),
        concentracion: _vacioComoNulo(_concentracion.text),
        formaFarmaceutica: _vacioComoNulo(_formaFarmaceutica.text),
        cantidad: _vacioComoNulo(_cantidad.text),
        posologia: _vacioComoNulo(_posologia.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.inicial == null ? 'Agregar medicamento' : 'Editar medicamento',
        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CampoTextoBlanco(
                label: 'Nombre del medicamento (Obligatorio)',
                icono: Icons.medication_outlined,
                controller: _nombre,
                enabled: true,
              ),
              const SizedBox(height: 12),
              _CampoTextoBlanco(
                label: 'Concentración/dosis (Obligatorio)',
                icono: Icons.science_outlined,
                controller: _concentracion,
                enabled: true,
              ),
              const SizedBox(height: 12),
              _CampoFormaFarmaceutica(controller: _formaFarmaceutica),
              const SizedBox(height: 12),
              _CampoTextoBlanco(
                label: 'Cantidad solicitada (Obligatorio)',
                icono: Icons.numbers_outlined,
                controller: _cantidad,
                enabled: true,
              ),
              const SizedBox(height: 12),
              _CampoTextoBlanco(
                label: 'Posología / indicaciones de uso (Opcional)',
                icono: Icons.schedule_outlined,
                controller: _posologia,
                enabled: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.navy)),
        ),
        AnimatedBuilder(
          animation: Listenable.merge([_nombre, _concentracion, _formaFarmaceutica, _cantidad]),
          builder: (context, _) => TextButton(
            onPressed: _datosCompletos ? _aceptar : null,
            child: const Text('Aceptar', style: TextStyle(color: AppColors.teal)),
          ),
        ),
      ],
    );
  }
}

class _FilaResumenMedicamento extends StatelessWidget {
  const _FilaResumenMedicamento({
    required this.medicamento,
    required this.enabled,
    required this.onEditar,
    required this.onQuitar,
  });

  final Medicamento medicamento;
  final bool enabled;
  final VoidCallback onEditar;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final detalle = [
      medicamento.concentracion,
      medicamento.formaFarmaceutica,
      medicamento.cantidad,
    ].where((valor) => valor != null && valor.trim().isNotEmpty).join(' · ');

    return InkWell(
      onTap: enabled ? onEditar : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.medication_outlined, color: AppColors.navy, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicamento.nombre ?? 'Medicamento sin nombre',
                    style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
                  ),
                  if (detalle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(detalle, style: const TextStyle(color: AppColors.teal, fontSize: 13)),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.teal),
              tooltip: 'Quitar',
              onPressed: enabled ? onQuitar : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ====== FILA DE RECETA ======
class _FilaFotoReceta extends StatelessWidget {
  const _FilaFotoReceta({
    required this.tieneArchivo,
    required this.bytesLocal,
    required this.esPdfLocal,
    required this.urlServidor,
    required this.onElegir,
  });

  final bool tieneArchivo;
  final List<int>? bytesLocal;
  final bool esPdfLocal;
  final String? urlServidor;
  final VoidCallback? onElegir;

  bool get _urlEsPdf =>
      urlServidor != null && urlServidor!.split('?').first.toLowerCase().endsWith('.pdf');

  bool get _esImagenVisible => !esPdfLocal && !_urlEsPdf && (bytesLocal != null || urlServidor != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _esImagenVisible
                ? () => mostrarImagenCompleta(
                    context,
                    bytes: bytesLocal != null ? Uint8List.fromList(bytesLocal!) : null,
                    url: bytesLocal == null ? urlServidor : null,
                  )
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: _contenidoCentral(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tieneArchivo
                  ? (_esImagenVisible ? 'Foto de la receta — toca para verla' : 'Receta (PDF) subida')
                  : 'Foto de la receta — no subida',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: onElegir,
            child: Text(
              tieneArchivo ? 'Reemplazar' : 'Subir',
              style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenidoCentral() {
    if (bytesLocal != null) {
      if (esPdfLocal) {
        return const Icon(Icons.picture_as_pdf_outlined, color: AppColors.navy, size: 24);
      }
      return Image.memory(Uint8List.fromList(bytesLocal!), fit: BoxFit.cover);
    }
    if (urlServidor != null) {
      if (_urlEsPdf) {
        return const Icon(Icons.picture_as_pdf_outlined, color: AppColors.navy, size: 24);
      }
      return Image.network(
        urlServidor!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image_not_supported_outlined, color: AppColors.navy, size: 20),
      );
    }
    // Icono de hoja cuando no hay nada subido
    return const Icon(Icons.description_outlined, color: AppColors.navy, size: 24);
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppColors.teal, fontSize: 13),
            prefixIcon: const Icon(Icons.event_outlined, color: AppColors.teal),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
          child: Text(
            fecha != null ? _isoFecha(fecha!) : 'Selecciona una fecha',
            style: const TextStyle(color: AppColors.navy),
          ),
        ),
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