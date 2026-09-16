import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_image_viewer.dart';
import '../../domain/entities/medicamento.dart';
import '../../domain/entities/precio_pedido.dart';

/// Widgets de formulario de solicitud (HU-03), compartidos entre
/// `nueva_solicitud_screen.dart` (crear/editar un Borrador) y
/// `solicitar_edicion_pedido_screen.dart` (HU-07 ronda 4 — pedir
/// corrección de un pedido ya enviado) — mismo lenguaje visual en las
/// dos, sin duplicar la implementación (context.md Parte A, §23/24).

String? vacioComoNulo(String texto) => texto.trim().isEmpty ? null : texto.trim();

class TituloSeccionSolicitud extends StatelessWidget {
  const TituloSeccionSolicitud(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 16),
    );
  }
}

/// Campo blanco con borde gris claro — mismo estilo en toda la sección
/// de formularios de solicitud.
class CampoTextoBlanco extends StatelessWidget {
  const CampoTextoBlanco({
    super.key,
    required this.label,
    required this.icono,
    required this.controller,
    required this.enabled,
    this.focusNode,
  });

  final String label;
  final IconData icono;
  final TextEditingController controller;
  final bool enabled;
  /// Opcional — lo usa `NuevaSolicitudScreen` para saber cuándo el
  /// Paciente terminó de escribir la dirección (perdió el foco del
  /// campo) en vez de disparar el estimado de precio en cada pausa al
  /// tipear.
  final FocusNode? focusNode;

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
        focusNode: focusNode,
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

const List<String> formasFarmaceuticasSugeridas = [
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

/// Campo de forma farmacéutica con autocompletado — filtra
/// [formasFarmaceuticasSugeridas] a medida que se escribe, sin
/// restringir a la lista (admite texto libre).
class CampoFormaFarmaceutica extends StatefulWidget {
  const CampoFormaFarmaceutica({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<CampoFormaFarmaceutica> createState() => _CampoFormaFarmaceuticaState();
}

class _CampoFormaFarmaceuticaState extends State<CampoFormaFarmaceutica> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  List<String> _sugerencias = [];

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
      setState(() => _sugerencias = []);
      _ocultarSugerencias();
      return;
    }

    final sugerencias = formasFarmaceuticasSugeridas
        .where((opcion) => opcion.toLowerCase().contains(texto))
        .toList();

    if (sugerencias.isEmpty) {
      _ocultarSugerencias();
      setState(() => _sugerencias = []);
    } else {
      setState(() => _sugerencias = sugerencias);
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
                      setState(() => _sugerencias = []);
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

/// Diálogo de alta/edición de un medicamento — devuelve el
/// [Medicamento] resultante, o `null` si se cancela.
class DialogoMedicamento extends StatefulWidget {
  const DialogoMedicamento({super.key, this.inicial});

  final Medicamento? inicial;

  @override
  State<DialogoMedicamento> createState() => _DialogoMedicamentoState();
}

class _DialogoMedicamentoState extends State<DialogoMedicamento> {
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

  /// Bug real reportado: el campo ya sugiere/filtra sobre la lista
  /// disponible (se mantiene tal cual, con buscador), pero antes
  /// dejaba guardar cualquier texto libre igual — sin que el usuario
  /// eligiera una opción de la lista. Comparación insensible a
  /// mayúsculas: el usuario puede tipear la sugerencia exacta a mano
  /// sin necesidad de tocarla en el overlay.
  bool get _formaFarmaceuticaValida => formasFarmaceuticasSugeridas.any(
    (opcion) => opcion.toLowerCase() == _formaFarmaceutica.text.trim().toLowerCase(),
  );

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
    if (!_formaFarmaceuticaValida) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Forma farmacéutica no disponible',
            style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Elegí una de las opciones sugeridas — escribí para buscarla y tocá la que corresponda.',
            style: TextStyle(color: AppColors.navy),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido', style: TextStyle(color: AppColors.teal)),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      Medicamento(
        nombre: vacioComoNulo(_nombre.text),
        concentracion: vacioComoNulo(_concentracion.text),
        formaFarmaceutica: vacioComoNulo(_formaFarmaceutica.text),
        cantidad: vacioComoNulo(_cantidad.text),
        posologia: vacioComoNulo(_posologia.text),
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
        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoTextoBlanco(
                label: 'Nombre del medicamento (Obligatorio)',
                icono: Icons.medication_outlined,
                controller: _nombre,
                enabled: true,
              ),
              const SizedBox(height: 12),
              CampoTextoBlanco(
                label: 'Concentración/dosis (Obligatorio)',
                icono: Icons.science_outlined,
                controller: _concentracion,
                enabled: true,
              ),
              const SizedBox(height: 12),
              CampoFormaFarmaceutica(controller: _formaFarmaceutica),
              const SizedBox(height: 12),
              CampoTextoBlanco(
                label: 'Cantidad solicitada (Obligatorio)',
                icono: Icons.numbers_outlined,
                controller: _cantidad,
                enabled: true,
              ),
              const SizedBox(height: 12),
              CampoTextoBlanco(
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

/// Fila resumen de un medicamento ya cargado — tocarla edita, la X quita.
class FilaResumenMedicamento extends StatelessWidget {
  const FilaResumenMedicamento({
    super.key,
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

enum OrigenArchivo { camara, galeria, pdf }

/// Resultado de [mostrarSelectorArchivo] — `null` si se canceló en
/// cualquier paso.
class ArchivoElegido {
  const ArchivoElegido({required this.bytes, required this.nombre, required this.contentType});

  final List<int> bytes;
  final String nombre;
  final String contentType;
}

/// Hoja inferior cámara/galería/PDF, mismo patrón en toda la app para
/// elegir un documento (HU-02, receta de HU-03). No sube nada — solo
/// devuelve los bytes elegidos, quien llama decide cuándo persistirlos.
Future<ArchivoElegido?> mostrarSelectorArchivo(BuildContext context) async {
  final origen = await showModalBottomSheet<OrigenArchivo>(
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
            onTap: () => Navigator.of(context).pop(OrigenArchivo.camara),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.teal),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.of(context).pop(OrigenArchivo.galeria),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.teal),
            title: const Text('Elegir PDF'),
            onTap: () => Navigator.of(context).pop(OrigenArchivo.pdf),
          ),
        ],
      ),
    ),
  );
  if (origen == null) return null;

  List<int>? bytes;
  String? nombre;
  String contentType = 'image/jpeg';

  if (origen == OrigenArchivo.pdf) {
    final archivo = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['pdf']);
    if (archivo == null) return null;
    bytes = await archivo.readAsBytes();
    nombre = archivo.name;
    contentType = 'application/pdf';
  } else {
    final archivo = await ImagePicker().pickImage(
      source: origen == OrigenArchivo.camara ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (archivo == null) return null;
    bytes = await archivo.readAsBytes();
    nombre = archivo.name;
    contentType = nombre.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
  }

  return ArchivoElegido(bytes: bytes, nombre: nombre, contentType: contentType);
}

/// Fila de "foto de la receta" — miniatura tocable (zoom si es imagen),
/// texto de estado, botón Subir/Reemplazar.
class FilaFotoReceta extends StatelessWidget {
  const FilaFotoReceta({
    super.key,
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
    // Bug real reportado: antes, sin archivo todavía, tocar el ícono o
    // el texto no hacía nada — solo "Subir" respondía. Ahora, si
    // todavía no hay archivo, toda la fila abre el selector (el
    // `GestureDetector` de la miniatura solo aplica cuando SÍ hay
    // imagen, para el zoom — ver más abajo, no se toca ese caso).
    return InkWell(
      onTap: !tieneArchivo ? onElegir : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
            // Con archivo ya subido, el "Reemplazar" sigue siendo su
            // propio botón independiente (la fila ya no abre el
            // selector al tocarla en ese estado — tocar la miniatura
            // hace zoom, tocar acá reemplaza).
            TextButton(
              onPressed: onElegir,
              child: Text(
                tieneArchivo ? 'Reemplazar' : 'Subir',
                style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
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
    return const Icon(Icons.description_outlined, color: AppColors.navy, size: 24);
  }
}

/// Confirmación de qué entendió la geocodificación de una dirección de
/// farmacia/entrega — vive debajo del campo de texto correspondiente
/// (bug real reportado: antes quedaba escondida dentro de la tarjeta
/// de precio, sin relación visual con el campo). Tres estados,
/// distinguidos por ÍCONO — nunca por color semántico (paleta oficial
/// únicamente, ver context.md): confirmada (check), imprecisa (lugar
/// grande sin punto exacto) y fallida (Nominatim no encontró nada).
class MensajeConfirmacionDireccion extends StatelessWidget {
  const MensajeConfirmacionDireccion({
    super.key,
    required this.cargando,
    required this.resuelta,
    required this.precisa,
    required this.fallo,
    this.candidatos = const [],
    this.onVerAlternativas,
  });

  /// Mientras se está esperando la respuesta de geocodificación.
  final bool cargando;
  /// La dirección tal como Nominatim la entendió — `null` si todavía
  /// no se intentó (campo vacío o el otro campo sigue incompleto) o si
  /// se intentó y no hubo resultado.
  final String? resuelta;
  /// `false` cuando SÍ se geocodificó pero es un lugar grande sin
  /// punto de entrega exacto (ej. "Universidad de Medellín").
  final bool precisa;
  /// Se intentó geocodificar y Nominatim no devolvió nada — distinto
  /// de "todavía no se intentó" (`resuelta == null` sin `fallo`).
  final bool fallo;
  /// Ronda 11 — otras coincidencias que Nominatim devolvió para la
  /// misma búsqueda. Bug real reportado: un Paciente registrado en un
  /// municipio (ej. Amagá) puede estar pidiendo desde otro (ej. San
  /// Antonio de Prado) — cuando la dirección elegida no es precisa, se
  /// ofrece elegir entre estas en vez de quedarse con la aproximación
  /// automática.
  final List<CandidatoDireccion> candidatos;
  final VoidCallback? onVerAlternativas;

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return _fila(
        icono: Icons.search,
        texto: 'Verificando dirección…',
        relleno: false,
      );
    }
    if (fallo) {
      return _fila(
        icono: Icons.location_off_outlined,
        texto: 'No pudimos ubicar esta dirección — revisala antes de enviar.',
        relleno: true,
      );
    }
    if (resuelta == null) {
      return const SizedBox.shrink();
    }
    if (!precisa) {
      return _fila(
        icono: Icons.info_outline,
        texto:
            '$resuelta — es un lugar grande, agregá más detalle si podés (bloque, portería, entrada).',
        relleno: true,
        enlace: candidatos.isNotEmpty ? '¿No es acá? Elegí otra dirección' : null,
        onEnlace: candidatos.isNotEmpty ? onVerAlternativas : null,
      );
    }
    return _fila(
      icono: Icons.check_circle_outline,
      texto: resuelta!,
      relleno: false,
    );
  }

  Widget _fila({
    required IconData icono,
    required String texto,
    required bool relleno,
    String? enlace,
    VoidCallback? onEnlace,
  }) {
    final fila = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 14, color: AppColors.navy),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                texto,
                style: const TextStyle(color: AppColors.navy, fontSize: 12, height: 1.3),
              ),
              if (enlace != null)
                InkWell(
                  onTap: onEnlace,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      enlace,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    if (!relleno) {
      return Padding(
        padding: const EdgeInsets.only(left: 14, right: 8, top: 6),
        child: fila,
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.skyBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.18)),
      ),
      child: fila,
    );
  }
}

/// Modal para elegir entre los candidatos alternos que Nominatim
/// devolvió, cuando la dirección elegida automáticamente no es
/// precisa — ver `MensajeConfirmacionDireccion.onVerAlternativas`.
Future<CandidatoDireccion?> mostrarSelectorDireccion(
  BuildContext context, {
  required String direccionElegida,
  required List<CandidatoDireccion> candidatos,
}) {
  return showModalBottomSheet<CandidatoDireccion>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Elegí la dirección correcta',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Encontramos varias coincidencias — elegí la que corresponde.',
                style: TextStyle(color: AppColors.teal, fontSize: 13),
              ),
              const SizedBox(height: 12),
              for (final candidato in candidatos)
                InkWell(
                  onTap: () => Navigator.of(context).pop(candidato),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          candidato.precisa
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          size: 16,
                          color: AppColors.navy,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            candidato.direccionResuelta,
                            style: const TextStyle(color: AppColors.navy, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Ninguna — seguir con la escrita',
                  style: TextStyle(color: AppColors.teal),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
