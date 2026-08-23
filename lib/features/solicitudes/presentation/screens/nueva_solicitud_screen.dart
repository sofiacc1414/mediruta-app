import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_icon_badge.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../usuarios/presentation/providers/perfil_providers.dart';
import '../../domain/entities/datos_solicitud.dart';
import '../../domain/entities/medicamento.dart';
import '../providers/solicitud_providers.dart';

/// G01/G04 — HU-03. Crear una solicitud nueva (`solicitudId == null`,
/// borrador guardado solo en el dispositivo hasta confirmar — nada viaja
/// a la API mientras se completa) o editar una ya existente en Borrador
/// (`solicitudId != null`, carga y guarda directo contra la API).
///
/// La receta (foto) sigue el mismo diferido que la solicitud entera: se
/// elige acá pero recién se sube (`SubirRecetaUseCase`) dentro de
/// `_persistir()`, cuando ya existe un id remoto — nunca antes de
/// confirmar. La foto elegida (bytes en memoria) NO se guarda en el
/// borrador local junto con el resto de los campos — si la app se
/// cierra de golpe antes de confirmar, los campos de texto sobreviven
/// pero la foto elegida hay que volver a elegirla (limitación aceptada,
/// evita tener que codificar imágenes en base64 dentro de
/// `shared_preferences`).
class NuevaSolicitudScreen extends ConsumerStatefulWidget {
  const NuevaSolicitudScreen({super.key, this.solicitudId});

  static const routeName = '/solicitudes/nueva';

  final String? solicitudId;

  @override
  ConsumerState<NuevaSolicitudScreen> createState() => _NuevaSolicitudScreenState();
}

class _LineaMedicamento {
  _LineaMedicamento({Medicamento? inicial})
    : nombre = TextEditingController(text: inicial?.nombre ?? ''),
      concentracion = TextEditingController(text: inicial?.concentracion ?? ''),
      formaFarmaceutica = TextEditingController(text: inicial?.formaFarmaceutica ?? ''),
      cantidad = TextEditingController(text: inicial?.cantidad ?? ''),
      posologia = TextEditingController(text: inicial?.posologia ?? '');

  final TextEditingController nombre;
  final TextEditingController concentracion;
  final TextEditingController formaFarmaceutica;
  final TextEditingController cantidad;
  final TextEditingController posologia;

  List<TextEditingController> get controllers => [
    nombre,
    concentracion,
    formaFarmaceutica,
    cantidad,
    posologia,
  ];

  Medicamento aMedicamento() {
    return Medicamento(
      nombre: _vacioComoNulo(nombre.text),
      concentracion: _vacioComoNulo(concentracion.text),
      formaFarmaceutica: _vacioComoNulo(formaFarmaceutica.text),
      cantidad: _vacioComoNulo(cantidad.text),
      posologia: _vacioComoNulo(posologia.text),
    );
  }

  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
  }
}

String? _vacioComoNulo(String texto) => texto.trim().isEmpty ? null : texto.trim();

class _NuevaSolicitudScreenState extends ConsumerState<NuevaSolicitudScreen> {
  final List<_LineaMedicamento> _lineas = [];
  final _direccionEntrega = TextEditingController();
  DateTime? _recetaFechaExpedicion;

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
    _inicializar();
  }

  @override
  void dispose() {
    _direccionEntrega.dispose();
    for (final linea in _lineas) {
      linea.dispose();
    }
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
          recetaFechaExpedicion: solicitud.recetaFechaExpedicion,
          direccionEntrega: solicitud.direccionEntrega,
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

    if (_lineas.isEmpty) {
      _agregarLinea(notificar: false);
    }
    if (mounted) setState(() => _cargandoInicial = false);
  }

  void _rellenar(DatosSolicitud datos) {
    for (final medicamento in datos.medicamentos) {
      _agregarLinea(inicial: medicamento, notificar: false);
    }
    _direccionEntrega.text = datos.direccionEntrega ?? '';
    if (datos.recetaFechaExpedicion != null) {
      _recetaFechaExpedicion = DateTime.tryParse(datos.recetaFechaExpedicion!);
    }
  }

  void _agregarLinea({Medicamento? inicial, bool notificar = true}) {
    final linea = _LineaMedicamento(inicial: inicial);
    for (final c in linea.controllers) {
      c.addListener(_onCambioCampo);
    }
    setState(() => _lineas.add(linea));
    if (notificar) _onCambioCampo();
  }

  void _quitarLinea(int indice) {
    final linea = _lineas.removeAt(indice);
    linea.dispose();
    setState(() {});
    _onCambioCampo();
  }

  DatosSolicitud _datosActuales() {
    return DatosSolicitud(
      medicamentos: _lineas.map((l) => l.aMedicamento()).toList(),
      recetaFechaExpedicion: _recetaFechaExpedicion != null ? _isoFecha(_recetaFechaExpedicion!) : null,
      direccionEntrega: _vacioComoNulo(_direccionEntrega.text),
    );
  }

  /// Mientras se crea (no edita), cada cambio se guarda solo en el
  /// dispositivo — nunca en la API — para que sobreviva aunque cierren
  /// la app de golpe, sin gastar red/BD mientras se está escribiendo.
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
          datos.recetaFechaExpedicion != null ||
          datos.direccionEntrega != null;
    }
    final actuales = _datosActuales();
    final originales = _datosOriginales;
    return hayRecetaPendiente ||
        originales == null ||
        actuales.toJson().toString() != originales.toJson().toString();
  }

  /// Crea (si es nueva) o actualiza (si ya existe) con los valores
  /// actuales, y sube la receta pendiente si había una elegida. Único
  /// punto donde esta pantalla habla con la API para persistir datos.
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

  Future<void> _elegirFotoReceta() async {
    final origen = await showModalBottomSheet<_OrigenArchivo>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(context).pop(_OrigenArchivo.camara),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(context).pop(_OrigenArchivo.galeria),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
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
                        const _TituloSeccion('Medicamentos'),
                        const SizedBox(height: 4),
                        const Text(
                          'Una fórmula puede traer más de uno — agregá una línea por cada uno.',
                          style: TextStyle(color: AppColors.teal, fontSize: 13),
                        ),
                        for (var i = 0; i < _lineas.length; i++) ...[
                          const SizedBox(height: 12),
                          _TarjetaMedicamento(
                            indice: i,
                            linea: _lineas[i],
                            enabled: !_guardando,
                            onQuitar: _lineas.length > 1 ? () => _quitarLinea(i) : null,
                          ),
                        ],
                        const SizedBox(height: 12),
                        AppButton(
                          variante: AppButtonVariante.secondary,
                          label: 'Agregar medicamento',
                          onPressed: _guardando ? null : () => _agregarLinea(),
                        ),
                        const SizedBox(height: 24),
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

/// Una línea de medicamento editable, con botón de quitar (deshabilitado
/// si es la única que queda — siempre tiene que haber al menos una).
class _TarjetaMedicamento extends StatelessWidget {
  const _TarjetaMedicamento({
    required this.indice,
    required this.linea,
    required this.enabled,
    required this.onQuitar,
  });

  final int indice;
  final _LineaMedicamento linea;
  final bool enabled;
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Medicamento ${indice + 1}',
                  style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
                ),
              ),
              if (onQuitar != null)
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.teal),
                  tooltip: 'Quitar',
                  onPressed: onQuitar,
                ),
            ],
          ),
          const SizedBox(height: 8),
          AppTextField(
            label: 'Nombre del medicamento',
            icono: Icons.medication_outlined,
            controller: linea.nombre,
            enabled: enabled,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Concentración/dosis',
            icono: Icons.science_outlined,
            controller: linea.concentracion,
            enabled: enabled,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Forma farmacéutica',
            icono: Icons.category_outlined,
            controller: linea.formaFarmaceutica,
            enabled: enabled,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Cantidad solicitada',
            icono: Icons.numbers_outlined,
            controller: linea.cantidad,
            enabled: enabled,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Posología / indicaciones de uso',
            icono: Icons.schedule_outlined,
            controller: linea.posologia,
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}

/// Fila de subida de la foto de la receta — cámara/galería/PDF, mismo
/// patrón que los documentos de HU-02. Muestra una miniatura de lo ya
/// elegido: `Image.memory` si se acaba de tomar/elegir en esta misma
/// sesión (todavía no subido), o `Image.network` si ya estaba subida
/// (editando una solicitud existente).
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 44,
            height: 44,
            color: AppColors.beige,
            child: _miniatura(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tieneArchivo ? 'Foto de la receta' : 'Foto de la receta — no subida',
            style: const TextStyle(color: AppColors.navy),
          ),
        ),
        TextButton(
          onPressed: onElegir,
          child: Text(tieneArchivo ? 'Reemplazar' : 'Subir'),
        ),
      ],
    );
  }

  Widget _miniatura() {
    if (bytesLocal != null) {
      if (esPdfLocal) {
        return const Icon(Icons.picture_as_pdf_outlined, color: AppColors.navy, size: 22);
      }
      return Image.memory(Uint8List.fromList(bytesLocal!), fit: BoxFit.cover);
    }
    if (urlServidor != null) {
      if (_urlEsPdf) {
        return const Icon(Icons.picture_as_pdf_outlined, color: AppColors.navy, size: 22);
      }
      return Image.network(
        urlServidor!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image_not_supported_outlined, color: AppColors.navy, size: 20),
      );
    }
    return const SizedBox.shrink();
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
