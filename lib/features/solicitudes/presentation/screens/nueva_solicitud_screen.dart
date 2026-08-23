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
import '../../../../shared/widgets/app_image_viewer.dart';
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

String? _vacioComoNulo(String texto) => texto.trim().isEmpty ? null : texto.trim();

class _NuevaSolicitudScreenState extends ConsumerState<NuevaSolicitudScreen> {
  /// Cada medicamento se agrega/edita en un diálogo aparte (ver
  /// `_DialogoMedicamento`) — antes se mostraban 5 campos editables en
  /// línea todo el tiempo, junto al botón "Agregar medicamento", y era
  /// confuso cuál de los dos hacía falta usar. Acá solo se guarda el
  /// valor ya confirmado (`Medicamento`, no controllers) — la lista se
  /// muestra como filas resumen, tocar una la vuelve a abrir para editar.
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
    _medicamentos.addAll(datos.medicamentos);
    _direccionEntrega.text = datos.direccionEntrega ?? '';
    _direccionFarmacia.text = datos.direccionFarmacia ?? '';
    if (datos.recetaFechaVencimiento != null) {
      _recetaFechaVencimiento = DateTime.tryParse(datos.recetaFechaVencimiento!);
    }
  }

  /// Abre el diálogo de agregar (`indice == null`) o editar (`indice`
  /// apunta a la línea existente) un medicamento. `null` en el resultado
  /// significa que se canceló — no toca la lista.
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
      } else {
        _medicamentos.add(resultado);
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
        title: const Text('¡Pedido enviado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tu solicitud pasó a revisión. Guardá este código de pedido:'),
            const SizedBox(height: 12),
            Text(
              codigoPedido,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
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

  /// A diferencia de una fecha de expedición (siempre pasada), la de
  /// vencimiento normalmente es futura — pero también tiene que poder
  /// elegirse una ya pasada: es justamente el caso que
  /// `calcularFaltantes`/`app.enviar_solicitud` necesitan poder detectar
  /// ("receta vencida"), no algo que el selector deba impedir de entrada.
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
                        if (_medicamentos.isEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Todavía no agregaste ningún medicamento.',
                            style: TextStyle(color: AppColors.teal, fontSize: 13),
                          ),
                        ],
                        for (var i = 0; i < _medicamentos.length; i++) ...[
                          const SizedBox(height: 12),
                          _FilaResumenMedicamento(
                            medicamento: _medicamentos[i],
                            enabled: !_guardando,
                            onEditar: () => _abrirDialogoMedicamento(indice: i),
                            onQuitar: () => _quitarMedicamento(i),
                          ),
                        ],
                        const SizedBox(height: 12),
                        AppButton(
                          variante: AppButtonVariante.secondary,
                          label: 'Agregar medicamento',
                          onPressed: _guardando ? null : () => _abrirDialogoMedicamento(),
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
                          label: 'Fecha de vencimiento de la receta',
                          fecha: _recetaFechaVencimiento,
                          onTap: _guardando ? null : _elegirFechaReceta,
                        ),
                        const SizedBox(height: 24),
                        const _TituloSeccion('Farmacia'),
                        const SizedBox(height: 4),
                        const Text(
                          'Dónde el domiciliario retira el medicamento.',
                          style: TextStyle(color: AppColors.teal, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Dirección de la farmacia',
                          icono: Icons.local_pharmacy_outlined,
                          controller: _direccionFarmacia,
                          enabled: !_guardando,
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

/// Presentaciones más comunes en fórmulas médicas colombianas — sugeridas
/// en `_CampoFormaFarmaceutica`, no una lista cerrada (una fórmula real a
/// veces trae una presentación fuera de esta lista, por eso el campo
/// sigue aceptando cualquier texto tipeado/pegado).
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

/// Compara sin distinguir mayúsculas/acentos — para que "capsula" (sin
/// tilde, como muchas personas tipean en el celular) igual encuentre
/// "Cápsula" al filtrar.
String _normalizar(String texto) {
  const conAcento = 'áéíóúÁÉÍÓÚñÑ';
  const sinAcento = 'aeiouAEIOUnN';
  var resultado = texto.toLowerCase();
  for (var i = 0; i < conAcento.length; i++) {
    resultado = resultado.replaceAll(conAcento[i].toLowerCase(), sinAcento[i].toLowerCase());
  }
  return resultado;
}

/// Campo de forma farmacéutica: sugiere presentaciones comunes y filtra
/// a medida que se escribe (más fluido que un desplegable rígido), pero
/// no restringe — el texto tipeado/pegado se guarda tal cual aunque no
/// esté en la lista. `RawAutocomplete` con `textEditingController`
/// propio evita tener que sincronizar dos controllers a mano.
class _CampoFormaFarmaceutica extends StatelessWidget {
  const _CampoFormaFarmaceutica({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: FocusNode(),
      optionsBuilder: (textEditingValue) {
        final filtro = _normalizar(textEditingValue.text.trim());
        if (filtro.isEmpty) return _formasFarmaceuticasSugeridas;
        return _formasFarmaceuticasSugeridas.where(
          (opcion) => _normalizar(opcion).contains(filtro),
        );
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        return AppTextField(
          label: 'Forma farmacéutica',
          icono: Icons.category_outlined,
          controller: fieldController,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 320),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final opcion = options.elementAt(index);
                  return ListTile(
                    title: Text(opcion),
                    onTap: () => onSelected(opcion),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Diálogo para agregar o editar una línea de medicamento — antes se
/// mostraban 5 campos editables en línea todo el tiempo junto al botón
/// "Agregar medicamento", confuso cuál de los dos correspondía usar. Se
/// completa acá y recién al aceptar aparece como fila resumen en la
/// lista; tocar esa fila reabre este mismo diálogo con sus datos.
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
      title: Text(widget.inicial == null ? 'Agregar medicamento' : 'Editar medicamento'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Nombre del medicamento',
                icono: Icons.medication_outlined,
                controller: _nombre,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Concentración/dosis',
                icono: Icons.science_outlined,
                controller: _concentracion,
              ),
              const SizedBox(height: 12),
              _CampoFormaFarmaceutica(controller: _formaFarmaceutica),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Cantidad solicitada',
                icono: Icons.numbers_outlined,
                controller: _cantidad,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Posología / indicaciones de uso',
                icono: Icons.schedule_outlined,
                controller: _posologia,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AnimatedBuilder(
          animation: _nombre,
          builder: (context, _) => TextButton(
            onPressed: _nombre.text.trim().isEmpty ? null : _aceptar,
            child: const Text('Aceptar'),
          ),
        ),
      ],
    );
  }
}

/// Fila resumen de un medicamento ya agregado — tocarla abre el diálogo
/// para editarlo. Reemplaza a la tarjeta con 5 campos siempre visibles.
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.skyBlue),
        ),
        child: Row(
          children: [
            const Icon(Icons.medication_outlined, color: AppColors.teal),
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
                  if (!medicamento.estaCompleto) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'Faltan datos — toca para completar',
                      style: TextStyle(color: AppColors.teal, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
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

  bool get _esImagenVisible => !esPdfLocal && !_urlEsPdf && (bytesLocal != null || urlServidor != null);

  @override
  Widget build(BuildContext context) {
    return Row(
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
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 44,
              height: 44,
              color: AppColors.beige,
              child: _miniatura(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tieneArchivo
                ? (_esImagenVisible ? 'Foto de la receta — toca para verla' : 'Foto de la receta')
                : 'Foto de la receta — no subida',
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
